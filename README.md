# ScanForge — Professional Flutter QR & Barcode Scanner

Android and iOS toolkit for scanning, generating, and optionally uploading QR codes and barcodes as JSON to a server you configure in the app.

## Features

- Live camera scan (QR + common barcodes) with torch and camera flip
- Continuous scan or single-scan modes
- Scan from gallery images
- Local history with search, swipe-delete, and upload retry
- Generator for QR and barcodes (share / save to gallery)
- Configurable server upload (`POST` JSON)
- In-app Server API docs showing the exact JSON payload
- About screen with developer contact

## JSON upload contract

When **Upload to server** is enabled in Settings:

```http
POST <your-server-url>
Content-Type: application/json
Authorization: Bearer <optional-api-key>
```

```json
{
  "value": "https://example.com",
  "format": "qr_code",
  "scannedAt": "2026-11-13T10:40:00.000Z",
  "source": "camera",
  "deviceId": "anon-install-uuid"
}
```

The same structure is shown inside **Settings → Server API**.

## Run on a device

Camera scanning requires a physical phone (or emulator with a virtual camera).

```bash
flutter pub get
flutter run
```

Grant camera and photos permissions when prompted.

### Platforms

- Android: `minSdk` 23+, Internet + Camera permissions included
- iOS: camera and photo library usage descriptions included in `Info.plist`

## Project layout

```
lib/
  screens/     Scan, History, Generate, Settings, About, Result
  services/    History, Settings, Upload, Feedback
  widgets/     Overlay, API docs, code preview, result actions
  constants/   API contract + developer info
```

## About / contact

Shown in the app About screen as **Mohannad Haddad - Ayun Solutions**:

- Email: info@ayunts.com
- Mobile: +96899206639
- Website: https://ayunts.com

Edit [`lib/constants/developer_info.dart`](lib/constants/developer_info.dart) to change these later.

## Tests

```bash
flutter test
flutter analyze
```
