import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/constants/developer_info.dart';

void main() {
  test('developer info is configured', () {
    expect(DeveloperInfo.appName, 'ScanForge');
    expect(DeveloperInfo.name, 'Mohannad');
    expect(DeveloperInfo.role, 'Ayun Solutions');
    expect(DeveloperInfo.email, 'info@ayunts.com');
    expect(DeveloperInfo.phone, '+96899206639');
    expect(DeveloperInfo.website, 'https://ayunts.com');
  });
}
