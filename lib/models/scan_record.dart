enum UploadStatus { pending, sent, failed, skipped }

class ScanRecord {
  ScanRecord({
    required this.id,
    required this.value,
    required this.format,
    required this.scannedAt,
    required this.source,
    this.uploadStatus = UploadStatus.skipped,
  });

  final String id;
  final String value;
  final String format;
  final DateTime scannedAt;
  final String source;
  UploadStatus uploadStatus;

  bool get isUrl {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String get formatLabel {
    return format
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'value': value,
      'format': format,
      'scannedAt': scannedAt.toIso8601String(),
      'source': source,
      'uploadStatus': uploadStatus.name,
    };
  }

  factory ScanRecord.fromMap(Map<dynamic, dynamic> map) {
    return ScanRecord(
      id: map['id'] as String,
      value: map['value'] as String,
      format: map['format'] as String,
      scannedAt: DateTime.parse(map['scannedAt'] as String),
      source: map['source'] as String? ?? 'camera',
      uploadStatus: UploadStatus.values.firstWhere(
        (status) => status.name == map['uploadStatus'],
        orElse: () => UploadStatus.skipped,
      ),
    );
  }

  ScanRecord copyWith({UploadStatus? uploadStatus}) {
    return ScanRecord(
      id: id,
      value: value,
      format: format,
      scannedAt: scannedAt,
      source: source,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }
}
