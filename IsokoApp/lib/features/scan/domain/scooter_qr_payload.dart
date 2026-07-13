class ScooterQrPayload {
  const ScooterQrPayload({
    required this.publicCode,
    this.rawValue,
  });

  final String publicCode;
  final String? rawValue;

  static final RegExp _publicCodePattern = RegExp(r'^BK\d{4,}$', caseSensitive: false);

  static ScooterQrPayload parse(String rawValue) {
    final trimmed = rawValue.trim();

    if (trimmed.isEmpty) {
      throw const FormatException('QR code is empty.');
    }

    final uri = Uri.tryParse(trimmed);
    final pathSegments = uri?.pathSegments ?? const <String>[];
    final candidate = _candidateFromUri(uri, pathSegments) ?? _candidateFromPlainText(trimmed);
    final normalized = candidate.toUpperCase();

    if (!_publicCodePattern.hasMatch(normalized)) {
      throw FormatException('QR code does not contain a valid scooter code: $rawValue');
    }

    return ScooterQrPayload(publicCode: normalized, rawValue: rawValue);
  }

  static String? _candidateFromUri(Uri? uri, List<String> pathSegments) {
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    if (uri.scheme == 'isoko' && uri.host == 'scooter' && pathSegments.isNotEmpty) {
      return pathSegments.first;
    }

    final scooterIndex = pathSegments.indexWhere((segment) => segment == 'scooters' || segment == 's');
    if (scooterIndex >= 0 && scooterIndex + 1 < pathSegments.length) {
      return pathSegments[scooterIndex + 1];
    }

    return uri.queryParameters['scooter'] ?? uri.queryParameters['code'];
  }

  static String _candidateFromPlainText(String value) {
    if (value.toUpperCase().startsWith('ISOKO:')) {
      return value.substring('ISOKO:'.length);
    }

    return value;
  }
}
