import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/constants/store_listing.dart';

void main() {
  group('Google Play SEO limits', () {
    test('title fits Play Store limit and includes brand + keywords', () {
      expect(StoreListing.playTitle.length, lessThanOrEqualTo(30));
      expect(StoreListing.playTitle, contains('ScanForge'));
      expect(StoreListing.playTitle.toLowerCase(), contains('qr'));
      expect(StoreListing.playTitle.toLowerCase(), contains('barcode'));
      expect(StoreListing.playTitle.toLowerCase(), contains('scanner'));
    });

    test('short description fits limit and sells core value', () {
      expect(StoreListing.playShortDescription.length, lessThanOrEqualTo(80));
      expect(StoreListing.playShortDescription.toLowerCase(), contains('scan'));
      expect(StoreListing.playShortDescription.toLowerCase(), contains('qr'));
      expect(
        StoreListing.playShortDescription.toLowerCase(),
        contains('barcode'),
      );
      expect(
        StoreListing.playShortDescription.toLowerCase(),
        contains('history'),
      );
    });

    test('full description fits limit and covers SEO phrases', () {
      expect(StoreListing.playFullDescription.length, lessThanOrEqualTo(4000));
      expect(StoreListing.playFullDescription.length, greaterThan(500));
      for (final phrase in StoreListing.requiredSeoPhrases) {
        expect(
          StoreListing.playFullDescription.toLowerCase(),
          contains(phrase.toLowerCase()),
          reason: 'Play full description missing "$phrase"',
        );
      }
      expect(StoreListing.playFullDescription, contains(StoreListing.supportEmail));
      expect(StoreListing.playFullDescription, contains(StoreListing.supportUrl));
      expect(StoreListing.playFullDescription, contains(StoreListing.developerName));
    });

    test('keyword list is focused and non-empty', () {
      expect(StoreListing.playKeywords, isNotEmpty);
      expect(StoreListing.playKeywords.length, lessThanOrEqualTo(20));
      for (final keyword in StoreListing.playKeywords) {
        expect(keyword.trim(), isNotEmpty);
        expect(keyword.length, lessThanOrEqualTo(50));
      }
      expect(
        StoreListing.playKeywords.any((k) => k.toLowerCase().contains('qr')),
        isTrue,
      );
      expect(
        StoreListing.playKeywords.any(
          (k) => k.toLowerCase().contains('barcode'),
        ),
        isTrue,
      );
    });
  });

  group('App Store SEO limits', () {
    test('name and subtitle fit App Store limits', () {
      expect(StoreListing.iosName.length, lessThanOrEqualTo(30));
      expect(StoreListing.iosSubtitle.length, lessThanOrEqualTo(30));
      expect(StoreListing.iosName, contains('ScanForge'));
      expect(StoreListing.iosName.toLowerCase(), contains('qr'));
      expect(StoreListing.iosName.toLowerCase(), contains('barcode'));
      expect(StoreListing.iosSubtitle.toLowerCase(), contains('scan'));
      expect(StoreListing.iosSubtitle.toLowerCase(), contains('upload'));
    });

    test('promotional text fits limit and highlights toolkit', () {
      expect(StoreListing.iosPromotionalText.length, lessThanOrEqualTo(170));
      expect(StoreListing.iosPromotionalText.toLowerCase(), contains('qr'));
      expect(StoreListing.iosPromotionalText.toLowerCase(), contains('barcode'));
      expect(StoreListing.iosPromotionalText.toLowerCase(), contains('scan'));
    });

    test('description fits limit and covers SEO phrases', () {
      expect(StoreListing.iosDescription.length, lessThanOrEqualTo(4000));
      expect(StoreListing.iosDescription.length, greaterThan(400));
      for (final phrase in StoreListing.requiredSeoPhrases) {
        expect(
          StoreListing.iosDescription.toLowerCase(),
          contains(phrase.toLowerCase()),
          reason: 'iOS description missing "$phrase"',
        );
      }
      expect(StoreListing.iosDescription, contains(StoreListing.supportEmail));
      expect(StoreListing.iosDescription, contains(StoreListing.supportUrl));
    });

    test('keywords fit 100-char limit and avoid spaces after commas', () {
      expect(StoreListing.iosKeywords.length, lessThanOrEqualTo(100));
      expect(StoreListing.iosKeywords.contains(', '), isFalse);
      final parts = StoreListing.iosKeywords.split(',');
      expect(parts.length, greaterThanOrEqualTo(5));
      for (final part in parts) {
        expect(part.trim(), isNotEmpty);
        expect(part, equals(part.trim()));
      }
      expect(StoreListing.iosKeywords.toLowerCase(), contains('qr'));
      expect(StoreListing.iosKeywords.toLowerCase(), contains('barcode'));
      expect(StoreListing.iosKeywords.toLowerCase(), contains('scanner'));
    });
  });

  group('Store listing JSON stays in sync', () {
    test('store_listing.json mirrors Dart constants', () {
      final file = File('store/listing/store_listing.json');
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final play = json['googlePlay'] as Map<String, dynamic>;
      final ios = json['appStore'] as Map<String, dynamic>;

      expect(json['appName'], StoreListing.appName);
      expect(json['developerName'], StoreListing.developerName);
      expect(json['supportEmail'], StoreListing.supportEmail);
      expect(json['supportUrl'], StoreListing.supportUrl);

      expect(play['title'], StoreListing.playTitle);
      expect(play['shortDescription'], StoreListing.playShortDescription);
      expect(
        (play['fullDescription'] as String).trim(),
        StoreListing.playFullDescription.trim(),
      );
      expect(
        List<String>.from(play['keywords'] as List),
        StoreListing.playKeywords,
      );

      expect(ios['name'], StoreListing.iosName);
      expect(ios['subtitle'], StoreListing.iosSubtitle);
      expect(ios['promotionalText'], StoreListing.iosPromotionalText);
      expect(
        (ios['description'] as String).trim(),
        StoreListing.iosDescription.trim(),
      );
      expect(ios['keywords'], StoreListing.iosKeywords);
    });

    test('screenshot captions cover all generated phone assets', () {
      final listing = jsonDecode(
        File('store/listing/store_listing.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final captions = List<Map<String, dynamic>>.from(
        listing['screenshotCaptions'] as List,
      );
      expect(captions.length, greaterThanOrEqualTo(5));

      final phoneDir = Directory('store/screenshots/phone');
      expect(phoneDir.existsSync(), isTrue);
      final files = phoneDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toSet();

      for (final caption in captions) {
        final name = caption['file'] as String;
        expect(files, contains(name), reason: 'Missing screenshot $name');
        expect((caption['caption'] as String).trim(), isNotEmpty);
        expect((caption['altText'] as String).toLowerCase(), contains('scan'));
      }
    });
  });

  group('In-app strings stay SEO-aligned', () {
    test('developer tagline mentions QR and barcode', () {
      expect(StoreListing.appName, 'ScanForge');
      // Cross-check pubspec description is keyword-rich via JSON listing.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.toLowerCase(), contains('qr'));
      expect(pubspec.toLowerCase(), contains('barcode'));
      expect(pubspec.toLowerCase(), contains('scanner'));
    });

    test('Android label and iOS display name use ScanForge', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:label="ScanForge"'));

      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('<string>ScanForge</string>'));
      expect(plist.toLowerCase(), contains('qr'));
      expect(plist.toLowerCase(), contains('barcode'));
    });
  });
}
