import 'package:dio/dio.dart';

import 'envelope.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class PlankaApi {
  final String serverUrl;
  String? token;
  late final Dio dio;

  PlankaApi(this.serverUrl, this.token) {
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
    final item = res['item'];
    if (item is! String) {
      throw ApiException(null, 'Unexpected login response');
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
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : e.message ?? 'Request failed';
      throw ApiException(e.response?.statusCode, message);
    }
  }
}
