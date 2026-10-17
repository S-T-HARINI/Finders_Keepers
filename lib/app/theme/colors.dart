import 'package:flutter/material.dart';

/// Campus Signal — Color Design Tokens
///
/// All colors used in the Finders Keepers app are defined here.
/// Never hardcode hex values elsewhere; always reference these tokens.
abstract final class CSColors {
  // ─── Backgrounds ──────────────────────────────────────────────────────────
  /// Warm ivory — primary app background. Evokes paper, permanence, and calm.
  static const Color paperWhite = Color(0xFFF7F4EE);

  /// Slightly deeper paper for elevated surfaces
  static const Color paperDark = Color(0xFFEFEBE3);

  /// Near-white for cards atop paper background
  static const Color surfaceCard = Color(0xFFFAF8F4);

  // ─── Text ─────────────────────────────────────────────────────────────────
  /// Near-black — primary text. Rich, legible, editorial.
  static const Color inkBlack = Color(0xFF1A1917);

  /// Dark graphite — secondary text, metadata, timestamps
  static const Color inkSecondary = Color(0xFF3D3B38);

  /// Medium graphite — placeholder, disabled, tertiary
  static const Color graphite = Color(0xFF6B6860);

  /// Light graphite — dividers, borders, subtle separators
  static const Color graphiteLight = Color(0xFFB8B4AC);

  /// Very subtle graphite — hairline dividers
  static const Color graphiteHairline = Color(0xFFDDDAD4);

  // ─── Accent ───────────────────────────────────────────────────────────────
  /// Signal Lime — primary accent. Energetic, visible, distinctive.
  static const Color signalLime = Color(0xFFB8E04A);

  /// Deeper lime for pressed/active states
  static const Color signalLimeDark = Color(0xFF96C230);

  /// Very subtle lime tint for backgrounds
  static const Color signalLimeTint = Color(0xFFF2FAD8);

  // ─── Status Colors ────────────────────────────────────────────────────────
  /// Lost item status — warm alert orange
  static const Color statusLost = Color(0xFFE8824A);

  /// Lost item tint
  static const Color statusLostTint = Color(0xFFFDF0E8);

  /// Found item status — muted sage green
  static const Color statusFound = Color(0xFF4A9B6F);

  /// Found item tint
  static const Color statusFoundTint = Color(0xFFE8F5EE);

  /// Claimed status — deep teal
  static const Color statusClaimed = Color(0xFF3A7B9B);

  /// Claimed tint
  static const Color statusClaimedTint = Color(0xFFE4F2F8);

  /// Returned status — graphite (resolved, complete)
  static const Color statusReturned = Color(0xFF6B6860);

  /// Returned tint
  static const Color statusReturnedTint = Color(0xFFEEECE8);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  /// Error / destructive actions
  static const Color error = Color(0xFFC94F4F);

  /// Error tint
  static const Color errorTint = Color(0xFFFAECEC);

  /// Success confirmation
  static const Color success = Color(0xFF4A9B6F);

  // ─── Shadow ───────────────────────────────────────────────────────────────
  /// Subtle shadow color for elevated surfaces
  static const Color shadow = Color(0x14000000);

  /// Stronger shadow for modals
  static const Color shadowStrong = Color(0x28000000);

  // ─── Aliases & Convenience Tokens ──────────────────────────────────────────
  static const Color textPrimary = inkBlack;
  static const Color textSecondary = inkSecondary;
  static const Color textMuted = graphite;
  static const Color textInverse = paperWhite;
  static const Color dividerLight = graphiteHairline;
  static const Color accentLime = signalLime;
  static const Color accentLimeDark = signalLimeDark;
  static const Color accentLimeLight = signalLimeTint;
  static const Color bgPaper = paperWhite;
  static const Color surface = surfaceCard;
  static const Color surfacePlaceholder = paperDark;
  static const Color warningOrange = statusLost;
  static const Color surfaceLostTint = statusLostTint;
  static const Color surfaceFoundTint = statusFoundTint;
}
