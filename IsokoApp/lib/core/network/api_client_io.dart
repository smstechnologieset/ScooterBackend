import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    HttpClient? httpClient,
    String? baseUrl,
    this.authTokenProvider,
  })  : _httpClient = httpClient ?? HttpClient(),
        _baseUri = Uri.parse(baseUrl ?? AppConfig.apiBaseUrl);

  final HttpClient _httpClient;
  final Uri _baseUri;
  final Future<String?> Function()? authTokenProvider;

  Future<Map<String, Object?>> getJson(String path) {
    return _sendJson('GET', path);
  }

  Future<Map<String, Object?>> postJson(
    String path, {
    Map<String, Object?> body = const {},
  }) {
    return _sendJson('POST', path, body: body);
  }

  Future<Map<String, Object?>> _sendJson(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final request = await _httpClient.openUrl(method, _baseUri.resolve(path));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    final token = await authTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded =
        responseBody.isEmpty ? <String, Object?>{} : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: decoded is Map && decoded['message'] is String
            ? decoded['message'] as String
            : 'Request failed.',
        statusCode: response.statusCode,
        body: decoded,
      );
    }

    if (decoded is Map<String, Object?>) {
      return decoded;
    }

    return {'data': decoded};
  }
}
