class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.statusCode,
    this.body,
  });

  final String message;
  final int statusCode;
  final Object? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
