import 'package:flutter/material.dart';

/// Campus Signal — Spacing & Sizing Tokens
///
/// Consistent spacing scale used throughout the app.
/// Follow the 4px base grid; use named constants only.
abstract final class CSSpacing {
  // ─── Base spacing scale ───────────────────────────────────────────────────
  static const double xs2 = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 40.0;
  static const double xxl = 64.0;
  static const double xxxl = 96.0;

  // ─── Component-level ──────────────────────────────────────────────────────
  /// Standard screen horizontal padding
  static const double screenPadding = 20.0;

  /// Card internal padding
  static const double cardPadding = 16.0;

  /// Section vertical gap
  static const double sectionGap = 32.0;

  /// List item vertical padding
  static const double listItemVPadding = 12.0;

  /// Bottom nav height
  static const double bottomNavHeight = 64.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  // ─── Border radii ─────────────────────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ─── Icon sizes ───────────────────────────────────────────────────────────
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ─── Touch targets ────────────────────────────────────────────────────────
  /// Minimum touch target per accessibility guidelines
  static const double touchTarget = 48.0;

  // ─── Content ──────────────────────────────────────────────────────────────
  /// Max content width for wide screens
  static const double maxContentWidth = 480.0;

  /// Item card image aspect ratio
  static const double cardImageRatio = 4 / 3;
}
