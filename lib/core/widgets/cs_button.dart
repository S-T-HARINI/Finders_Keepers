import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Campus Signal — Status Label
///
/// A compact, typographically distinctive label for item states.
/// Uses a tight rectangular form with a colored left border accent.
enum CSStatusVariant { lost, found, claimed, returned }

class CSStatusLabel extends StatelessWidget {
  const CSStatusLabel({
    this.variant = CSStatusVariant.lost,
    this.text,
    this.color,
    super.key,
    this.small = false,
  });

  final CSStatusVariant variant;
  final String? text;
  final Color? color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final labelText = text ?? config.label;
    final accentColor = color ?? config.accentColor;
    final tintColor = color != null ? color!.withValues(alpha: 0.12) : config.tintColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? CSSpacing.xs : CSSpacing.sm,
        vertical: small ? 2 : CSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(CSSpacing.radiusXs),
        border: Border(
          left: BorderSide(color: accentColor, width: 2.5),
        ),
      ),
      child: Text(
        labelText.toUpperCase(),
        style: (small ? CSTypography.labelSmall : CSTypography.labelMedium)
            .copyWith(
          color: accentColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  _LabelConfig get _config => switch (variant) {
        CSStatusVariant.lost => const _LabelConfig(
            label: 'Lost',
            accentColor: CSColors.statusLost,
            tintColor: CSColors.statusLostTint,
          ),
        CSStatusVariant.found => const _LabelConfig(
            label: 'Found',
            accentColor: CSColors.statusFound,
            tintColor: CSColors.statusFoundTint,
          ),
        CSStatusVariant.claimed => const _LabelConfig(
            label: 'Claimed',
            accentColor: CSColors.statusClaimed,
            tintColor: CSColors.statusClaimedTint,
          ),
        CSStatusVariant.returned => const _LabelConfig(
            label: 'Returned',
            accentColor: CSColors.statusReturned,
            tintColor: CSColors.statusReturnedTint,
          ),
      };
}

class _LabelConfig {
  const _LabelConfig({
    required this.label,
    required this.accentColor,
    required this.tintColor,
  });
  final String label;
  final Color accentColor;
  final Color tintColor;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Campus Signal — Primary Button
///
/// Full-width or auto-width button using Signal Lime accent.
/// Communicates actionability without decorative excess.
class CSPrimaryButton extends StatefulWidget {
  const CSPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  State<CSPrimaryButton> createState() => _CSPrimaryButtonState();
}

class _CSPrimaryButtonState extends State<CSPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: CSMotion.instant,
      lowerBound: 0.96,
    );
    _scale = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.loading;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _scaleController.reverse(),
      onTapUp: isDisabled ? null : (_) => _scaleController.forward(),
      onTapCancel: isDisabled ? null : () => _scaleController.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: CSSpacing.touchTarget,
          child: ElevatedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            child: widget.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CSColors.inkBlack,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: CSSpacing.iconSm),
                        const SizedBox(width: CSSpacing.sm),
                      ],
                      Text(widget.label),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Campus Signal — Secondary (Outlined) Button
class CSSecondaryButton extends StatelessWidget {
  const CSSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: CSSpacing.touchTarget,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: CSSpacing.iconSm),
              const SizedBox(width: CSSpacing.sm),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
