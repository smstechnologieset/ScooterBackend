// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    Object? httpClient,
    String? baseUrl,
    this.authTokenProvider,
  }) : _baseUri = Uri.parse(baseUrl ?? AppConfig.apiBaseUrl);

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
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = await authTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await html.HttpRequest.request(
      _baseUri.resolve(path).toString(),
      method: method,
      requestHeaders: headers,
      sendData: body == null ? null : jsonEncode(body),
    );
    final responseBody = response.responseText ?? '';
    final decoded =
        responseBody.isEmpty ? <String, Object?>{} : jsonDecode(responseBody);
    final status = response.status ?? 0;

    if (status < 200 || status >= 300) {
      throw ApiException(
        message: decoded is Map && decoded['message'] is String
            ? decoded['message'] as String
            : 'Request failed.',
        statusCode: status,
        body: decoded,
      );
    }

    if (decoded is Map<String, Object?>) {
      return decoded;
    }

    return {'data': decoded};
  }
}
