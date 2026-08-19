import 'package:dio/dio.dart';

import 'envelope.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// A fresh Planka server requires accepting its Terms of Service before it
/// will issue a token. [login] throws this instead of returning; the caller
/// confirms with the user, calls [PlankaApi.acceptTerms], then retries login.
class TermsRequiredException implements Exception {
  final String pendingToken;
  TermsRequiredException(this.pendingToken);

  @override
  String toString() => 'TermsRequiredException';
}

/// A server with two-factor authentication enabled rejects login with 403
/// {step: verify-totp, pendingToken}. [login] throws this instead of returning;
/// the caller collects a code and calls [PlankaApi.verifyTotp].
///
/// For the ten minutes it lives, the pending token converts into a full access
/// token on six digits, so it is worth what the password is worth: hold it in
/// memory for the length of the step, never persist it, and never render it —
/// hence the constant [toString], since `showApiError` prints '$error' for
/// anything it does not recognise.
class TotpRequiredException implements Exception {
  final String pendingToken;
  TotpRequiredException(this.pendingToken);

  @override
  String toString() => 'TotpRequiredException';
}

/// The server rejected the submitted code (403). The pending token is still
/// valid, so the caller stays on the code step and can try again.
class TotpCodeRejectedException implements Exception {
  @override
  String toString() => 'TotpCodeRejectedException';
}

/// The pending token was invalid, or its ten-minute window closed (401). The
/// caller must start again from credentials. This is *not* session expiry —
/// no session exists yet.
class TotpPendingTokenExpiredException implements Exception {
  @override
  String toString() => 'TotpPendingTokenExpiredException';
}

/// Planka serves attachment and cover images behind session-cookie auth rather
/// than the Bearer header the REST API uses. Both image widgets send exactly
/// these headers — the single source of truth for the download-auth scheme.
Map<String, String> imageAuthHeaders(String token) =>
    {'Cookie': 'accessToken=$token'};

/// The `Authorization` header value for token auth. Single source for the REST
/// interceptor, the accept-terms call, and the socket handshake.
String bearerAuth(String token) => 'Bearer $token';

class PlankaApi {
  final String serverUrl;
  String? token;
  late final Dio dio;

  /// Called once per 401 on an authenticated request (session expiry).
  final void Function()? onUnauthorized;

  PlankaApi(this.serverUrl, this.token, {this.onUnauthorized}) {
    dio = Dio(BaseOptions(baseUrl: '$serverUrl/api'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = token;
        if (t != null) options.headers['Authorization'] = bearerAuth(t);
        handler.next(options);
      },
    ));
  }

  Future<String> login(String emailOrUsername, String password) async {
    final res = await _request(() => dio.post<Map<String, dynamic>>(
        '/access-tokens',
        data: {'emailOrUsername': emailOrUsername, 'password': password}));
    // A fresh server answers this with 403 {step:accept-terms} — surfaced as
    // TermsRequiredException from _request, so we never reach here in that case.
    final item = res['item'];
    if (item is! String) {
      throw ApiException(null, 'Unexpected login response');
    }
    token = item;
    return item;
  }

  /// Accept the server's Terms of Service using the [pendingToken] from a
  /// [TermsRequiredException]. The accept-terms endpoint returns a real access
  /// token, which this stores and returns — no re-login needed.
  Future<String> acceptTerms(String pendingToken) async {
    final opts = Options(headers: {'Authorization': bearerAuth(pendingToken)});
    final terms = await _request(
        () => dio.get<Map<String, dynamic>>('/terms', options: opts));
    final signature = (terms['item'] as Map?)?['signature'];
    if (signature is! String) {
      throw ApiException(null, 'Unexpected terms response');
    }
    final res = await _request(() => dio.post<Map<String, dynamic>>(
        '/access-tokens/accept-terms',
        data: {'pendingToken': pendingToken, 'signature': signature}));
    final item = res['item'];
    if (item is! String) {
      throw ApiException(null, 'Unexpected accept-terms response');
    }
    token = item;
    return item;
  }

  /// Completes a two-factor login. [code] is a TOTP code or a recovery code —
  /// the server decides which it accepted, so nothing here may judge its shape.
  ///
  /// [pendingToken] is passed per call and is never assigned to [token]: only
  /// the real access token this returns is, so no response shape can leave the
  /// pending token sitting in the field that [CurrentAccountNotifier.signIn]
  /// persists.
  ///
  /// Deliberately bypasses [_request]: the server's 401/403 distinction has to
  /// survive to the caller, and neither the server's `message` nor the pending
  /// token may reach a user-visible string.
  Future<String> verifyTotp(String pendingToken, String code) async {
    final Response<Map<String, dynamic>> res;
    try {
      res = await dio.post<Map<String, dynamic>>('/access-tokens/verify-totp',
          data: {'pendingToken': pendingToken, 'code': code});
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 403:
          throw TotpCodeRejectedException();
        case 401:
          // Not onUnauthorized: there is no session to expire yet, so this must
          // never be mistaken for the signed-in session dying.
          throw TotpPendingTokenExpiredException();
      }
      // e.message describes the transport, never the response body — the body
      // could echo the pending token straight into a snackbar.
      throw ApiException(e.response?.statusCode, e.message ?? 'Request failed');
    }
    final item = (res.data ?? const {})['item'];
    if (item is! String) {
      throw ApiException(null, 'Unexpected verify-totp response');
    }
    token = item;
    return item;
  }

  Future<void> logout() async {
    await _request(() => dio.delete<Map<String, dynamic>>('/access-tokens/me'));
    token = null;
  }

  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse(await _request(
          () => dio.get<Map<String, dynamic>>(path, queryParameters: query)));

  Future<Envelope> post(String path, Object? body) async => Envelope.parse(
      await _request(() => dio.post<Map<String, dynamic>>(path, data: body)));

  Future<Envelope> patch(String path, Object? body) async => Envelope.parse(
      await _request(() => dio.patch<Map<String, dynamic>>(path, data: body)));

  Future<Envelope> delete(String path) async => Envelope.parse(
      await _request(() => dio.delete<Map<String, dynamic>>(path)));

  /// Downloads a server file (attachment download endpoint — root-level, not
  /// under /api, and cookie-authenticated like images) to [savePath].
  Future<void> download(String urlPath, String savePath) async {
    final t = token;
    if (t == null) throw ApiException(401, 'Not signed in');
    try {
      await dio.download('$serverUrl$urlPath', savePath,
          options: Options(headers: imageAuthHeaders(t)));
    } on DioException catch (e) {
      // Same session-expiry handling as _request: 401 with a token means the
      // session died, so kick off the re-login flow.
      if (e.response?.statusCode == 401) onUnauthorized?.call();
      throw ApiException(e.response?.statusCode, e.message ?? 'Download failed');
    }
  }

  Future<Map<String, dynamic>> _request(
      Future<Response<Map<String, dynamic>>> Function() send) async {
    try {
      final res = await send();
      return res.data ?? const {};
    } on DioException catch (e) {
      final data = e.response?.data;
      // Fresh server rejects login with 403 {step:accept-terms, pendingToken};
      // not a failure — the caller must accept terms then continue.
      if (data is Map &&
          data['step'] == 'accept-terms' &&
          data['pendingToken'] is String) {
        throw TermsRequiredException(data['pendingToken'] as String);
      }
      // A server with 2FA on rejects login with 403 {step:verify-totp,
      // pendingToken}. Like accept-terms this is a continuation of the login,
      // not a failure — the caller collects a code and calls verifyTotp.
      if (data is Map &&
          data['step'] == 'verify-totp' &&
          data['pendingToken'] is String) {
        throw TotpRequiredException(data['pendingToken'] as String);
      }
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : e.message ?? 'Request failed';
      // 401 with a token = expired session; 401 without = bad credentials.
      if (e.response?.statusCode == 401 && token != null) {
        onUnauthorized?.call();
      }
      throw ApiException(e.response?.statusCode, message);
    }
  }
}
