import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import 'motion.dart';

/// Campus Signal — App Theme
///
/// Builds the complete Material 3 [ThemeData] for the app.
/// Call [AppTheme.light] to obtain the theme.
abstract final class AppTheme {
  static ThemeData get light => _buildTheme();

  static ThemeData _buildTheme() {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: CSColors.signalLime,
      onPrimary: CSColors.inkBlack,
      primaryContainer: CSColors.signalLimeTint,
      onPrimaryContainer: CSColors.inkBlack,
      secondary: CSColors.graphite,
      onSecondary: CSColors.paperWhite,
      secondaryContainer: CSColors.paperDark,
      onSecondaryContainer: CSColors.inkBlack,
      tertiary: CSColors.statusFound,
      onTertiary: CSColors.paperWhite,
      tertiaryContainer: CSColors.statusFoundTint,
      onTertiaryContainer: CSColors.inkBlack,
      error: CSColors.error,
      onError: CSColors.paperWhite,
      errorContainer: CSColors.errorTint,
      onErrorContainer: CSColors.error,
      surface: CSColors.paperWhite,
      onSurface: CSColors.inkBlack,
      surfaceContainerHighest: CSColors.paperDark,
      onSurfaceVariant: CSColors.graphite,
      outline: CSColors.graphiteLight,
      outlineVariant: CSColors.graphiteHairline,
      shadow: CSColors.shadow,
      inverseSurface: CSColors.inkBlack,
      onInverseSurface: CSColors.paperWhite,
      inversePrimary: CSColors.signalLimeDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CSColors.paperWhite,
      textTheme: CSTypography.textTheme,
      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: CSColors.paperWhite,
        foregroundColor: CSColors.inkBlack,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: CSColors.shadow,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: CSTypography.headlineSmall,
        toolbarHeight: CSSpacing.appBarHeight,
        shape: const Border(
          bottom: BorderSide(color: CSColors.graphiteHairline, width: 0.5),
        ),
      ),
      // ── Navigation Bar ─────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CSColors.surfaceCard,
        indicatorColor: CSColors.signalLimeTint,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CSColors.inkBlack, size: 22);
          }
          return const IconThemeData(color: CSColors.graphite, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CSTypography.labelMedium.copyWith(
              color: CSColors.inkBlack,
              fontWeight: FontWeight.w600,
            );
          }
          return CSTypography.labelMedium;
        }),
        elevation: 0,
        height: CSSpacing.bottomNavHeight,
        surfaceTintColor: Colors.transparent,
        shadowColor: CSColors.shadow,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: CSColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
          side: const BorderSide(color: CSColors.graphiteHairline, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── Buttons ────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CSColors.signalLime,
          foregroundColor: CSColors.inkBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: CSSpacing.lg,
            vertical: CSSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
          ),
          textStyle: CSTypography.labelLarge,
          minimumSize: const Size(0, CSSpacing.touchTarget),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CSColors.inkBlack,
          side: const BorderSide(color: CSColors.graphiteLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: CSSpacing.lg,
            vertical: CSSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
          ),
          textStyle: CSTypography.labelLarge,
          minimumSize: const Size(0, CSSpacing.touchTarget),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CSColors.inkBlack,
          padding: const EdgeInsets.symmetric(
            horizontal: CSSpacing.sm,
            vertical: CSSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CSSpacing.radiusXs),
          ),
          textStyle: CSTypography.labelLarge,
        ),
      ),
      // ── Input / Search ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        fillColor: CSColors.paperDark,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
          borderSide: const BorderSide(color: CSColors.graphiteHairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
          borderSide: const BorderSide(color: CSColors.graphiteHairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
          borderSide:
              const BorderSide(color: CSColors.signalLimeDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
          borderSide: const BorderSide(color: CSColors.error),
        ),
        hintStyle: CSTypography.bodyMedium.copyWith(color: CSColors.graphite),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CSSpacing.md,
          vertical: CSSpacing.sm,
        ),
      ),
      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: CSColors.graphiteHairline,
        thickness: 0.5,
        space: 0,
      ),
      // ── Chips ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: CSColors.paperDark,
        selectedColor: CSColors.signalLimeTint,
        labelStyle: CSTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: CSSpacing.sm,
          vertical: CSSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CSSpacing.radiusXs),
          side: const BorderSide(color: CSColors.graphiteHairline),
        ),
      ),
      // ── Page transitions ───────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // ── Visual density ─────────────────────────────────────────────────────
      visualDensity: VisualDensity.standard,
      splashColor: CSColors.signalLimeTint,
      highlightColor: CSColors.signalLimeTint.withOpacity(0.5),
    );
  }
}
