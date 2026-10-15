import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../models/item_model.dart';
import 'cs_button.dart';

/// Campus Signal — Item Card
///
/// Asymmetric layout: category tag + status badge flush-left,
/// title in editorial style, metadata row at bottom.
/// Not a generic card grid cell — has deliberate hierarchy.
class CSItemCard extends StatelessWidget {
  const CSItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ItemModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CSColors.surfaceCard,
          borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
          border: Border.all(
            color: CSColors.graphiteHairline,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image placeholder area ──────────────────────────────────────
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(CSSpacing.radiusMd),
                  topRight: Radius.circular(CSSpacing.radiusMd),
                ),
                child: AspectRatio(
                  aspectRatio: CSSpacing.cardImageRatio,
                  child: Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImagePlaceholder(item: item),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(CSSpacing.radiusMd),
                  topRight: Radius.circular(CSSpacing.radiusMd),
                ),
                child: _ImagePlaceholder(item: item),
              ),
            // ── Content ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(CSSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + category row
                  Row(
                    children: [
                      CSStatusLabel(
                        variant: _statusVariant,
                        small: true,
                      ),
                      const SizedBox(width: CSSpacing.sm),
                      Expanded(
                        child: Text(
                          item.category.toUpperCase(),
                          style: CSTypography.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CSSpacing.sm),
                  // Title
                  Text(
                    item.title,
                    style: CSTypography.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: CSSpacing.xs),
                  // Description preview
                  Text(
                    item.description,
                    style: CSTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: CSSpacing.md),
                  // Metadata row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: CSColors.graphite,
                      ),
                      const SizedBox(width: CSSpacing.xs2),
                      Expanded(
                        child: Text(
                          item.locationLabel,
                          style: CSTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: CSSpacing.sm),
                      Text(
                        _formatDate(item.reportedAt),
                        style: CSTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  CSStatusVariant get _statusVariant => switch (item.type) {
        ItemType.lost => CSStatusVariant.lost,
        ItemType.found => CSStatusVariant.found,
      };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

/// Placeholder shown when no image is available.
/// Uses category color and a meaningful icon.
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final bg = item.type == ItemType.lost
        ? CSColors.statusLostTint
        : CSColors.statusFoundTint;
    final fg = item.type == ItemType.lost
        ? CSColors.statusLost
        : CSColors.statusFound;

    return AspectRatio(
      aspectRatio: CSSpacing.cardImageRatio,
      child: Container(
        color: bg,
        child: Center(
          child: Icon(
            _categoryIcon,
            size: 40,
            color: fg.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  IconData get _categoryIcon => switch (item.category.toLowerCase()) {
        'electronics' => Icons.devices_rounded,
        'documents' => Icons.badge_outlined,
        'accessories' => Icons.watch_outlined,
        'bags' => Icons.backpack_outlined,
        'keys' => Icons.key_outlined,
        'clothing' => Icons.checkroom_outlined,
        _ => Icons.search_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// Campus Signal — Empty State Card
///
/// Polished empty state for screens with no content yet.
/// Uses intentional whitespace and a clear primary action.
class CSEmptyState extends StatelessWidget {
  const CSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CSSpacing.xl,
        vertical: CSSpacing.xxl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: CSColors.paperDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: CSColors.graphite,
            ),
          ),
          const SizedBox(height: CSSpacing.lg),
          Text(
            title,
            style: CSTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CSSpacing.sm),
          Text(
            body,
            style: CSTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: CSSpacing.lg),
            CSPrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Campus Signal — Section Header
///
/// Asymmetric section heading: large label left, optional action right.
class CSSectionHeader extends StatelessWidget {
  const CSSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(title, style: CSTypography.headlineSmall),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: CSTypography.labelMedium.copyWith(
                color: CSColors.inkBlack,
                decoration: TextDecoration.underline,
                decorationColor: CSColors.signalLimeDark,
                decorationThickness: 2,
              ),
            ),
          ),
      ],
    );
  }
}
