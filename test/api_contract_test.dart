import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/constants/api_contract.dart';

void main() {
  test('buildPayload creates canonical JSON fields', () {
    final payload = ApiContract.buildPayload(
      value: 'ABC-123',
      format: 'code_128',
      scannedAt: DateTime.utc(2026, 11, 13, 10, 40),
      source: 'camera',
      deviceId: 'device-1',
    );

    expect(payload.keys, containsAll(['value', 'format', 'scannedAt', 'source', 'deviceId']));
    expect(payload['value'], 'ABC-123');
    expect(payload['format'], 'code_128');
    expect(payload['source'], 'camera');
    expect(payload['deviceId'], 'device-1');
    expect(payload['scannedAt'], '2026-11-13T10:40:00.000Z');
  });

  test('sample JSON documents the same contract', () {
    expect(ApiContract.sampleJson, contains('"value"'));
    expect(ApiContract.sampleJson, contains('"format"'));
    expect(ApiContract.sampleJson, contains('"scannedAt"'));
    expect(ApiContract.sampleJson, contains('"source"'));
    expect(ApiContract.sampleJson, contains('"deviceId"'));
  });
}
