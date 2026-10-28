/// Translates between rider-friendly short scooter codes (e.g. ISK-001 to ISK-020)
/// and real database device IDs without requiring database schema changes.
class ScooterCodeTranslator {
  const ScooterCodeTranslator._();

  // Static 1-to-1 mapping for fleet of up to 20 demo/pilot scooters
  static final Map<String, String> _friendlyToDevice = {
    for (var i = 1; i <= 20; i++)
      'ISK-${i.toString().padLeft(3, '0')}': '70000000000${i.toString().padLeft(2, '0')}',
  };

  // Reverse mapping from deviceId -> friendly code
  static final Map<String, String> _deviceToFriendly = {
    for (var entry in _friendlyToDevice.entries) entry.value: entry.key,
  };

  /// Normalizes user input (e.g., "1", "001", "isk001", "ISK-001")
  /// into the corresponding backend deviceId.
  static String toDeviceId(String input) {
    final cleaned = input.trim().toUpperCase().replaceAll(' ', '');

    if (cleaned.isEmpty) {
      return '';
    }

    // Check direct friendly code match (e.g., "ISK-001")
    if (_friendlyToDevice.containsKey(cleaned)) {
      return _friendlyToDevice[cleaned]!;
    }

    // Check without hyphen (e.g., "ISK001")
    if (cleaned.startsWith('ISK') && cleaned.length >= 4) {
      final numPart = cleaned.substring(3).replaceAll('-', '');
      final intVal = int.tryParse(numPart);
      if (intVal != null && intVal >= 1 && intVal <= 20) {
        final key = 'ISK-${intVal.toString().padLeft(3, '0')}';
        return _friendlyToDevice[key] ?? cleaned;
      }
    }

    // Check pure number input (e.g., "1", "01", "001")
    final intVal = int.tryParse(cleaned);
    if (intVal != null && intVal >= 1 && intVal <= 20) {
      final key = 'ISK-${intVal.toString().padLeft(3, '0')}';
      return _friendlyToDevice[key] ?? cleaned;
    }

    // Otherwise treat as raw deviceId
    return cleaned;
  }

  /// Converts a deviceId (or code) into a friendly display code like "ISK-001".
  static String toFriendlyCode(String deviceIdOrCode) {
    final cleaned = deviceIdOrCode.trim();

    if (_deviceToFriendly.containsKey(cleaned)) {
      return _deviceToFriendly[cleaned]!;
    }

    // If it's already a friendly code
    if (cleaned.toUpperCase().startsWith('ISK-')) {
      return cleaned.toUpperCase();
    }

    // Fallback: If deviceId ends with digits, create a clean short code
    if (cleaned.length > 6) {
      final suffix = cleaned.substring(cleaned.length - 3);
      final intVal = int.tryParse(suffix);
      if (intVal != null && intVal >= 1 && intVal <= 999) {
        return 'ISK-${intVal.toString().padLeft(3, '0')}';
      }
    }

    return cleaned;
  }

  /// Formats any scooter code or deviceId for clean UI display.
  static String formatDisplay(String rawCode) {
    return toFriendlyCode(rawCode);
  }
}
