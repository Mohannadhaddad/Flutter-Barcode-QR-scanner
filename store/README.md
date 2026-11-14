# Store assets

Marketing assets for Google Play and the Apple App Store.

## Listing copy

- Source of truth for tests: [`../lib/constants/store_listing.dart`](../lib/constants/store_listing.dart)
- JSON mirror for Console / App Store Connect paste: [`listing/store_listing.json`](listing/store_listing.json)
- Privacy policy URL: `https://www.ayunts.com/privacy-policy/`

SEO checks:

```bash
flutter test test/store_listing_seo_test.dart
```

## Feature graphic

Google Play feature graphic (`1024×500`): [`feature_graphic.png`](feature_graphic.png)

## Screenshots

Phone (`1080×1920`) and tablet (`1200×1920`) PNGs live under `screenshots/`.

Regenerate after icon or branding changes:

```bash
python3 tool/generate_store_screenshots.py
```
