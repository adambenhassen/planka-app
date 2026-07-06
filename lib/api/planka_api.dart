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
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
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
    final opts = Options(headers: {'Authorization': 'Bearer $pendingToken'});
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
