import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/widgets/cs_button.dart';

/// Welcome Screen — Finders Keepers entry point.
///
/// Design: Distinctive editorial layout with a strong asymmetric composition.
/// Left-aligned heading, tagline, and two CTAs. No login form in Phase 1.
/// Architecture boundary: Firebase Auth integration goes here in Phase 2.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar — brand mark ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CSSpacing.screenPadding,
                CSSpacing.lg,
                CSSpacing.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  _LimeDot(),
                  const SizedBox(width: CSSpacing.sm),
                  Text(
                    'Finders Keepers',
                    style: CSTypography.labelLarge.copyWith(
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Main visual — editorial composition ──────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CSSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Large editorial heading — DM Serif Display
                    RichText(
                      text: TextSpan(
                        style: CSTypography.displayMedium,
                        children: [
                          const TextSpan(text: 'Find what\'s\nlost.\n'),
                          TextSpan(
                            text: 'Return\nwhat\'s found.',
                            style: CSTypography.displayMedium.copyWith(
                              color: CSColors.graphite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CSSpacing.lg),

                    // Horizontal rule accent — Signal Lime
                    Container(
                      width: 48,
                      height: 3,
                      decoration: BoxDecoration(
                        color: CSColors.signalLime,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: CSSpacing.lg),

                    // Tagline
                    Text(
                      'A trusted campus network for reporting,\ndiscovering, and returning lost items.',
                      style: CSTypography.bodyLarge,
                    ),
                    const SizedBox(height: CSSpacing.xxl),

                    // CTAs
                    CSPrimaryButton(
                      label: 'Get started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.goNamed(AppRoutes.home),
                    ),
                    const SizedBox(height: CSSpacing.md),
                    CSSecondaryButton(
                      label: 'Browse without signing in',
                      onPressed: () => context.goNamed(AppRoutes.home),
                    ),

                    const SizedBox(height: CSSpacing.lg),
                    // Auth note
                    Text(
                      'Sign in required to report items or submit claims.',
                      style: CSTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),

            // ── Bottom — stats strip ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(CSSpacing.screenPadding),
              padding: const EdgeInsets.symmetric(
                horizontal: CSSpacing.md,
                vertical: CSSpacing.md,
              ),
              decoration: BoxDecoration(
                color: CSColors.paperDark,
                borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
                border: Border.all(color: CSColors.graphiteHairline, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const _StatCell(count: '—', label: 'Items reported'),
                  _Divider(),
                  const _StatCell(count: '—', label: 'Items returned'),
                  _Divider(),
                  const _StatCell(count: '—', label: 'Active users'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: CSColors.signalLime,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.count, required this.label});
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: CSTypography.headlineMedium.copyWith(
            fontFamily: 'DMSerifDisplay',
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: CSTypography.caption),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 32,
      color: CSColors.graphiteHairline,
    );
  }
}
