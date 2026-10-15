// Navigation widget tests for Finders Keepers
//
// These tests verify that:
// 1. The app bootstraps without errors
// 2. The Welcome screen renders correctly
// 3. All 5 screens are accessible via navigation
// 4. Bottom navigation tabs function correctly
//
// Run with: flutter test test/navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finders_keepers/app/app.dart';
import 'package:finders_keepers/app/router.dart';

void main() {
  group('App bootstraps', () {
    testWidgets('App renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FindersKeepersApp()),
      );
      // Allow GoRouter to settle
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Welcome Screen', () {
    testWidgets('Shows app name', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FindersKeepersApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Finders Keepers'), findsWidgets);
    });

    testWidgets('Shows Get started button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FindersKeepersApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('Shows tagline text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FindersKeepersApp()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('what\'s lost'), findsOneWidget);
    });
  });

  group('Navigation from Welcome to Home', () {
    testWidgets('Tapping Get started navigates to Home', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FindersKeepersApp()),
      );
      await tester.pumpAndSettle();

      // Find and tap the Get started button
      final getStartedButton = find.text('Get started');
      expect(getStartedButton, findsOneWidget);
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Should be on Home screen
      expect(find.text('Home'), findsWidgets);
    });
  });

  group('Bottom Navigation', () {
    Future<void> navigateToHome(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FindersKeepersApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
    }

    testWidgets('Bottom nav shows all 4 destinations', (tester) async {
      await navigateToHome(tester);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Explore'), findsWidgets);
      expect(find.text('Activity'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('Tapping Explore shows explore screen', (tester) async {
      await navigateToHome(tester);
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      // Explore screen has Map/List toggle
      expect(find.text('Map'), findsWidgets);
      expect(find.text('List'), findsWidgets);
    });

    testWidgets('Tapping Activity shows activity screen', (tester) async {
      await navigateToHome(tester);
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('My Activity'), findsWidgets);
      expect(find.text('My Reports'), findsOneWidget);
      expect(find.text('My Claims'), findsOneWidget);
    });

    testWidgets('Tapping Profile shows profile screen', (tester) async {
      await navigateToHome(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('Can navigate back to Home from Profile', (tester) async {
      await navigateToHome(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      // Should see "What are you looking for?" heading
      expect(find.textContaining('looking for'), findsOneWidget);
    });
  });

  group('Home Screen', () {
    Future<void> goToHome(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FindersKeepersApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
    }

    testWidgets('Shows Lost Items and Found Items entry cards', (tester) async {
      await goToHome(tester);
      expect(find.text('Lost Items'), findsOneWidget);
      expect(find.text('Found Items'), findsOneWidget);
    });

    testWidgets('Shows Recent Reports section', (tester) async {
      await goToHome(tester);
      expect(find.text('Recent Reports'), findsOneWidget);
    });

    testWidgets('Shows Report Item FAB', (tester) async {
      await goToHome(tester);
      expect(find.text('Report Item'), findsOneWidget);
    });

    testWidgets('Mock data disclaimer is visible', (tester) async {
      await goToHome(tester);
      expect(find.textContaining('Demo data'), findsOneWidget);
    });
  });
}
