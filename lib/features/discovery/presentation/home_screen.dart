import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/models/item_model.dart';
import '../../../core/widgets/cs_button.dart';
import '../../../core/widgets/cs_card.dart';
import '../../../core/widgets/cs_search_bar.dart';

/// Home / Discovery Screen
///
/// Design: Clear hierarchy — greeting / search / entry points / recent feed.
/// Asymmetric composition with a prominent search area and two category CTAs.
/// Uses mock data clearly labeled as such (Phase 1 only).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      body: CustomScrollView(
        slivers: [
          // ── App bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            titleSpacing: CSSpacing.screenPadding,
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CSColors.signalLime,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: CSSpacing.sm),
                Text(
                  'Finders Keepers',
                  style: CSTypography.titleMedium,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () {},
              ),
              const SizedBox(width: CSSpacing.xs),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: CSSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: CSSpacing.lg),

                // ── Greeting ─────────────────────────────────────────────────
                Text(
                  'What are\nyou looking for?',
                  style: CSTypography.displaySmall,
                ),
                const SizedBox(height: CSSpacing.lg),

                // ── Search ────────────────────────────────────────────────────
                CSSearchBar(
                  controller: _searchController,
                  hint: 'Keys, wallet, laptop bag…',
                ),
                const SizedBox(height: CSSpacing.lg),

                // ── Category CTAs: Lost | Found ───────────────────────────────
                _CategoryEntryRow(),
                const SizedBox(height: CSSpacing.sectionGap),

                // ── Recent items ──────────────────────────────────────────────
                CSSectionHeader(
                  title: 'Recent Reports',
                  actionLabel: 'See all',
                  onAction: () {},
                ),
                // Mock data disclaimer
                const SizedBox(height: CSSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CSSpacing.sm,
                    vertical: CSSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: CSColors.signalLimeTint,
                    borderRadius: BorderRadius.circular(CSSpacing.radiusXs),
                  ),
                  child: Text(
                    '⚙ Demo data — Phase 1 visual development',
                    style: CSTypography.caption.copyWith(
                      color: CSColors.signalLimeDark,
                    ),
                  ),
                ),
                const SizedBox(height: CSSpacing.md),

                // Item list
                ...MockItems.recent.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: CSSpacing.md),
                    child: CSItemCard(
                      item: item,
                      onTap: () {
                        // Phase 2: navigate to item detail
                      },
                    ),
                  ),
                ),
                const SizedBox(height: CSSpacing.xl),
              ]),
            ),
          ),
        ],
      ),

      // ── FAB — Report Item ────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Phase 2: navigate to report item flow
          _showReportBottomSheet(context);
        },
        backgroundColor: CSColors.signalLime,
        foregroundColor: CSColors.inkBlack,
        elevation: 2,
        label: Text('Report Item', style: CSTypography.labelLarge),
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Report a lost or found item',
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CSColors.paperWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CSSpacing.radiusLg),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(CSSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: CSSpacing.lg),
                decoration: BoxDecoration(
                  color: CSColors.graphiteLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('What happened?', style: CSTypography.headlineMedium),
            const SizedBox(height: CSSpacing.xs),
            Text(
              'Tell us whether you lost something or found something.',
              style: CSTypography.bodyMedium,
            ),
            const SizedBox(height: CSSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.search_off_rounded,
                    label: 'I lost\nsomething',
                    color: CSColors.statusLost,
                    tint: CSColors.statusLostTint,
                    onTap: () {
                      Navigator.pop(context);
                      // Phase 2: navigate to lost report flow
                    },
                  ),
                ),
                const SizedBox(width: CSSpacing.md),
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.volunteer_activism_rounded,
                    label: 'I found\nsomething',
                    color: CSColors.statusFound,
                    tint: CSColors.statusFoundTint,
                    onTap: () {
                      Navigator.pop(context);
                      // Phase 2: navigate to found report flow
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + CSSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryEntryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EntryCard(
            label: 'Lost Items',
            count: MockItems.lost.length,
            icon: Icons.search_off_rounded,
            accentColor: CSColors.statusLost,
            tintColor: CSColors.statusLostTint,
            onTap: () {},
          ),
        ),
        const SizedBox(width: CSSpacing.md),
        Expanded(
          child: _EntryCard(
            label: 'Found Items',
            count: MockItems.found.length,
            icon: Icons.volunteer_activism_rounded,
            accentColor: CSColors.statusFound,
            tintColor: CSColors.statusFoundTint,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.tintColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color tintColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(CSSpacing.md),
        decoration: BoxDecoration(
          color: tintColor,
          borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: accentColor),
                const Spacer(),
                Text(
                  '$count',
                  style: CSTypography.displaySmall.copyWith(
                    fontSize: 22,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CSSpacing.sm),
            Text(
              label,
              style: CSTypography.titleMedium.copyWith(color: accentColor),
            ),
            Text(
              'active reports',
              style: CSTypography.caption.copyWith(color: accentColor.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  const _ReportTypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(CSSpacing.md),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: CSSpacing.sm),
            Text(
              label,
              style: CSTypography.titleMedium.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
