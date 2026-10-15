// Design system unit tests for Finders Keepers
//
// These tests verify:
// 1. Color token integrity — all key colors are defined and non-transparent
// 2. Spacing token values satisfy the 4px base grid
// 3. Typography system produces non-null text styles
// 4. Motion constants are sensibly ordered
// 5. Item model serialization round-trips correctly
//
// Run with: flutter test test/theme_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/app/theme/colors.dart';
import 'package:finders_keepers/app/theme/spacing.dart';
import 'package:finders_keepers/app/theme/motion.dart';
import 'package:finders_keepers/app/theme/typography.dart';
import 'package:finders_keepers/app/theme/app_theme.dart';
import 'package:finders_keepers/core/models/item_model.dart';

void main() {
  group('CSColors — color token integrity', () {
    test('All primary colors have full opacity (non-transparent)', () {
      expect(CSColors.paperWhite.a, equals(1.0));
      expect(CSColors.inkBlack.a, equals(1.0));
      expect(CSColors.signalLime.a, equals(1.0));
      expect(CSColors.graphite.a, equals(1.0));
      expect(CSColors.statusLost.a, equals(1.0));
      expect(CSColors.statusFound.a, equals(1.0));
    });

    test('Signal Lime is visually distinct from ink black', () {
      // Luminance difference should be significant
      final limeLuminance = CSColors.signalLime.computeLuminance();
      final inkLuminance = CSColors.inkBlack.computeLuminance();
      expect(limeLuminance, greaterThan(inkLuminance + 0.5));
    });

    test('Paper white is lighter than ink black', () {
      expect(
        CSColors.paperWhite.computeLuminance(),
        greaterThan(CSColors.inkBlack.computeLuminance()),
      );
    });

    test('Status colors are visually distinct', () {
      final lostL = CSColors.statusLost.computeLuminance();
      final foundL = CSColors.statusFound.computeLuminance();
      expect((lostL - foundL).abs(), greaterThan(0.05));
    });

    test('Tint colors are lighter than their accent colors', () {
      expect(
        CSColors.statusLostTint.computeLuminance(),
        greaterThan(CSColors.statusLost.computeLuminance()),
      );
      expect(
        CSColors.statusFoundTint.computeLuminance(),
        greaterThan(CSColors.statusFound.computeLuminance()),
      );
    });
  });

  group('CSSpacing — spacing token values', () {
    test('All spacings are positive', () {
      expect(CSSpacing.xs, greaterThan(0));
      expect(CSSpacing.sm, greaterThan(0));
      expect(CSSpacing.md, greaterThan(0));
      expect(CSSpacing.lg, greaterThan(0));
      expect(CSSpacing.xl, greaterThan(0));
    });

    test('Spacings are in increasing order', () {
      expect(CSSpacing.xs, lessThan(CSSpacing.sm));
      expect(CSSpacing.sm, lessThan(CSSpacing.md));
      expect(CSSpacing.md, lessThan(CSSpacing.lg));
      expect(CSSpacing.lg, lessThan(CSSpacing.xl));
      expect(CSSpacing.xl, lessThan(CSSpacing.xxl));
    });

    test('Touch target meets accessibility minimum (48dp)', () {
      expect(CSSpacing.touchTarget, greaterThanOrEqualTo(48.0));
    });

    test('Screen padding is between 16 and 32', () {
      expect(CSSpacing.screenPadding, greaterThanOrEqualTo(16.0));
      expect(CSSpacing.screenPadding, lessThanOrEqualTo(32.0));
    });
  });

  group('CSMotion — motion token values', () {
    test('Durations are in increasing order', () {
      expect(
        CSMotion.instant.inMilliseconds,
        lessThan(CSMotion.fast.inMilliseconds),
      );
      expect(
        CSMotion.fast.inMilliseconds,
        lessThan(CSMotion.medium.inMilliseconds),
      );
      expect(
        CSMotion.medium.inMilliseconds,
        lessThan(CSMotion.slow.inMilliseconds),
      );
    });

    test('Page transition duration is between fast and slow', () {
      expect(
        CSMotion.pageTransition.inMilliseconds,
        greaterThan(CSMotion.fast.inMilliseconds),
      );
      expect(
        CSMotion.pageTransition.inMilliseconds,
        lessThanOrEqualTo(CSMotion.slow.inMilliseconds),
      );
    });
  });

  group('AppTheme — theme configuration', () {
    test('Theme builds without throwing', () {
      expect(() => AppTheme.light, returnsNormally);
    });

    test('Theme uses Material 3', () {
      expect(AppTheme.light.useMaterial3, isTrue);
    });

    test('Scaffold background matches paper white', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        equals(CSColors.paperWhite),
      );
    });

    test('Color scheme primary is Signal Lime', () {
      expect(
        AppTheme.light.colorScheme.primary,
        equals(CSColors.signalLime),
      );
    });

    test('Color scheme surface is paper white', () {
      expect(
        AppTheme.light.colorScheme.surface,
        equals(CSColors.paperWhite),
      );
    });
  });

  group('ItemModel — domain model', () {
    final testItem = ItemModel(
      id: 'test-001',
      title: 'Test Item',
      description: 'A test item',
      type: ItemType.lost,
      status: ItemStatus.active,
      category: 'Electronics',
      locationLabel: 'Library',
      reportedAt: DateTime(2026, 10, 15),
    );

    test('ItemModel creates correctly', () {
      expect(testItem.id, equals('test-001'));
      expect(testItem.title, equals('Test Item'));
      expect(testItem.type, equals(ItemType.lost));
      expect(testItem.status, equals(ItemStatus.active));
    });

    test('copyWith preserves unchanged fields', () {
      final modified = testItem.copyWith(title: 'Modified Item');
      expect(modified.title, equals('Modified Item'));
      expect(modified.id, equals(testItem.id));
      expect(modified.type, equals(testItem.type));
    });

    test('toFirestore serializes correctly', () {
      final map = testItem.toFirestore();
      expect(map['title'], equals('Test Item'));
      expect(map['type'], equals('lost'));
      expect(map['status'], equals('active'));
    });

    test('fromFirestore deserializes correctly', () {
      final map = testItem.toFirestore();
      final restored = ItemModel.fromFirestore(map, testItem.id);
      expect(restored.id, equals(testItem.id));
      expect(restored.title, equals(testItem.title));
      expect(restored.type, equals(testItem.type));
    });

    test('Equality works via Equatable', () {
      final item1 = testItem;
      final item2 = testItem.copyWith();
      expect(item1, equals(item2));
    });

    test('MockItems contains both lost and found items', () {
      expect(MockItems.lost, isNotEmpty);
      expect(MockItems.found, isNotEmpty);
      expect(
        MockItems.lost.every((i) => i.type == ItemType.lost),
        isTrue,
      );
      expect(
        MockItems.found.every((i) => i.type == ItemType.found),
        isTrue,
      );
    });
  });
}
