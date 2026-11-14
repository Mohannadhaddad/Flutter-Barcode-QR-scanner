/// App Store / Play Store listing copy used for SEO checks and publishing.
///
/// Keep this file in sync with `store/listing/store_listing.json`.
class StoreListing {
  static const String appName = 'ScanForge';
  static const String developerName = 'Mohannad Haddad - Ayun Solutions';
  static const String supportEmail = 'info@ayunts.com';
  static const String supportUrl = 'https://ayunts.com';
  static const String privacyPolicyUrl = 'https://www.ayunts.com/privacy-policy/';

  // Google Play limits: title ≤30, short ≤80, full ≤4000.
  static const String playTitle = 'ScanForge QR & Barcode Scanner';
  static const String playShortDescription =
      'QR & barcode scanner with history, generator, and optional JSON upload.';
  static const String playFullDescription = '''
ScanForge is a professional QR code and barcode scanner for Android. Scan live with your camera, import codes from gallery images, generate new QR codes and barcodes, keep a searchable local history, and optionally upload every scan as JSON to your own server.

KEY FEATURES
• Fast live camera scanning for QR codes and common barcodes
• Continuous scan or single-scan modes with torch and camera flip
• Scan QR codes and barcodes from gallery photos
• Local history with search, swipe-delete, and upload retry
• Prevent duplicate scans with configurable cooldown
• Beep, vibrate, and auto-copy feedback controls
• QR and barcode generator — share or save to gallery
• Configurable JSON server upload with optional API key
• In-app Server API docs showing the exact payload
• Light and dark themes

WHO IT IS FOR
Inventory checks, warehouse ops, event check-in, IT asset labels, retail barcodes, Wi-Fi QR codes, and any workflow that needs a reliable QR barcode scanner with optional server sync.

PRIVACY FIRST
Scans stay on your device unless you enable upload. When upload is on, ScanForge POSTs JSON you control to the server URL you configure — no third-party scan cloud required.

Built by Mohannad Haddad - Ayun Solutions.
Support: info@ayunts.com · https://ayunts.com''';

  static const List<String> playKeywords = [
    'QR code scanner',
    'barcode scanner',
    'QR scanner',
    'barcode reader',
    'QR code generator',
    'barcode generator',
    'scan QR code',
    'inventory scanner',
    'QR barcode scanner',
    'JSON upload scanner',
  ];

  // App Store limits: name ≤30, subtitle ≤30, promotional ≤170,
  // description ≤4000, keywords ≤100 (comma-separated).
  static const String iosName = 'ScanForge QR Barcode';
  static const String iosSubtitle = 'Scan, Generate & Upload';
  static const String iosPromotionalText =
      'Professional QR & barcode toolkit — live scan, history, generator, and optional JSON server upload.';
  static const String iosDescription = '''
ScanForge is a professional QR code and barcode scanner. Scan live with the camera, import codes from photos, generate QR codes and barcodes, keep searchable history, and optionally upload scans as JSON to your own server.

FEATURES
• Live QR code and barcode scanning with torch and camera flip
• Continuous or single-scan modes
• Gallery image scanning
• Searchable history with swipe-delete and upload retry
• Duplicate prevention with cooldown windows
• Beep, vibrate, and auto-copy controls
• Generate QR codes and barcodes — share or save
• Configurable JSON upload with optional API key
• In-app Server API documentation
• Light and dark appearance

Built for inventory, retail, events, IT labels, and custom workflows that need a dependable QR barcode scanner without forcing a third-party cloud.

Developer: Mohannad Haddad - Ayun Solutions
Support: info@ayunts.com · https://ayunts.com''';

  static const String iosKeywords =
      'QR scanner,barcode,QR code,barcode reader,QR generator,inventory,scan QR,code scanner,JSON,warehouse';

  /// Core SEO phrases that must appear across store copy.
  static const List<String> requiredSeoPhrases = [
    'QR',
    'barcode',
    'scanner',
    'ScanForge',
    'history',
    'generate',
    'upload',
    'JSON',
  ];
}
