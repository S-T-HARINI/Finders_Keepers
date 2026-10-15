import 'package:flutter/material.dart';

/// Campus Signal — Motion Tokens
///
/// Restrained transitions that communicate state changes without slowing
/// down the experience. Prefer snappy interactions over elaborate animations.
abstract final class CSMotion {
  // ─── Durations ────────────────────────────────────────────────────────────
  /// Instant — for immediate feedback (e.g., button press color)
  static const Duration instant = Duration(milliseconds: 80);

  /// Fast — for small UI state changes (icons, labels, indicators)
  static const Duration fast = Duration(milliseconds: 150);

  /// Medium — for panel transitions, expanding sections
  static const Duration medium = Duration(milliseconds: 250);

  /// Slow — for page transitions, major layout shifts
  static const Duration slow = Duration(milliseconds: 380);

  // ─── Curves ───────────────────────────────────────────────────────────────
  /// Standard easing for most transitions
  static const Curve standard = Curves.easeInOut;

  /// Decelerate — for elements entering the screen
  static const Curve enter = Curves.easeOutCubic;

  /// Accelerate — for elements leaving the screen
  static const Curve exit = Curves.easeInCubic;

  /// Spring-like — for interactive feedback
  static const Curve spring = Curves.elasticOut;

  // ─── Page transitions ─────────────────────────────────────────────────────
  /// Duration for screen-to-screen navigation
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// Curve for page push (forward navigation)
  static const Curve pagePushCurve = Curves.easeOutCubic;

  /// Curve for page pop (back navigation)
  static const Curve pagePopCurve = Curves.easeInCubic;
}
