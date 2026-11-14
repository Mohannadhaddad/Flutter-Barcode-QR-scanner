class ApiContract {
  static const String method = 'POST';
  static const String contentType = 'application/json';
  static const String authHeader = 'Authorization: Bearer <apiKey>';

  static const List<ApiField> fields = [
    ApiField(
      name: 'value',
      type: 'string',
      description: 'Raw barcode / QR payload',
    ),
    ApiField(
      name: 'format',
      type: 'string',
      description: 'Code type (e.g. qr_code)',
    ),
    ApiField(
      name: 'scannedAt',
      type: 'string',
      description: 'ISO-8601 UTC timestamp',
    ),
    ApiField(
      name: 'source',
      type: 'string',
      description: 'camera or gallery',
    ),
    ApiField(
      name: 'deviceId',
      type: 'string',
      description: 'Anonymous device id',
    ),
  ];

  static const String sampleJson = '''{
  "value": "https://example.com",
  "format": "qr_code",
  "scannedAt": "2026-11-13T10:40:00.000Z",
  "source": "camera",
  "deviceId": "anon-install-uuid"
}''';

  static Map<String, dynamic> buildPayload({
    required String value,
    required String format,
    required DateTime scannedAt,
    required String source,
    required String deviceId,
  }) {
    return {
      'value': value,
      'format': format,
      'scannedAt': scannedAt.toUtc().toIso8601String(),
      'source': source,
      'deviceId': deviceId,
    };
  }
}

class ApiField {
  const ApiField({
    required this.name,
    required this.type,
    required this.description,
  });

  final String name;
  final String type;
  final String description;
}
