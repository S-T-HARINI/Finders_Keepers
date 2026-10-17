import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_model.dart';
import '../../../core/widgets/cs_card.dart';
import '../../../core/widgets/cs_search_bar.dart';
import '../../items/data/item_repository.dart';

/// Home / Discovery Screen
///
/// Design: Clear editorial hierarchy — greeting / search / entry points / recent feed.
/// Asymmetric composition with a prominent search area and two category CTAs.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  ItemType? _selectedTypeFilter;
  String? _selectedCategoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = (
      type: _selectedTypeFilter,
      category: _selectedCategoryFilter,
      query: _searchController.text,
    );

    final itemsAsync = ref.watch(filteredItemsStreamProvider(filter));

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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
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
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: CSSpacing.lg),

                // ── Category CTAs: Lost | Found ───────────────────────────────
                _CategoryEntryRow(
                  selectedType: _selectedTypeFilter,
                  onSelectType: (type) {
                    setState(() {
                      if (_selectedTypeFilter == type) {
                        _selectedTypeFilter = null; // Toggle off filter
                      } else {
                        _selectedTypeFilter = type;
                      }
                    });
                  },
                ),
                const SizedBox(height: CSSpacing.sectionGap),

                // ── Recent items ──────────────────────────────────────────────
                CSSectionHeader(
                  title: _selectedTypeFilter == null
                      ? 'Recent Reports'
                      : (_selectedTypeFilter == ItemType.lost ? 'Lost Items' : 'Found Items'),
                  actionLabel: _selectedTypeFilter != null ? 'Show all' : null,
                  onAction: () {
                    setState(() {
                      _selectedTypeFilter = null;
                      _selectedCategoryFilter = null;
                      _searchController.clear();
                    });
                  },
                ),
                // Mock/Live data status banner
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
                    'Demo data · Connect Firebase for live reports — Finders Keepers',
                    style: CSTypography.caption.copyWith(
                      color: CSColors.signalLimeDark,
                    ),
                  ),
                ),
                const SizedBox(height: CSSpacing.md),

                // Item list from provider
                itemsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: CSColors.textPrimary)),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('Error loading feed: $err')),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.inbox_outlined, size: 48, color: CSColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No matching reports found',
                                style: CSTypography.headlineSmall.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing filters or search terms',
                                style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: CSSpacing.md),
                          child: CSItemCard(
                            item: item,
                            onTap: () {
                              context.push('/items/${item.id}');
                            },
                          ),
                        ),
                      ).toList(),
                    );
                  },
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
      builder: (bottomSheetContext) => Padding(
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
                      Navigator.pop(bottomSheetContext);
                      context.push(AppConstants.kRouteReportItem, extra: ItemType.lost);
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
                      Navigator.pop(bottomSheetContext);
                      context.push(AppConstants.kRouteReportItem, extra: ItemType.found);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(bottomSheetContext).viewInsets.bottom + CSSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryEntryRow extends ConsumerWidget {
  const _CategoryEntryRow({
    required this.selectedType,
    required this.onSelectType,
  });

  final ItemType? selectedType;
  final ValueChanged<ItemType> onSelectType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItems = ref.watch(filteredItemsStreamProvider(
      (type: null, category: null, query: ''),
    )).valueOrNull ?? MockItems.all;

    final lostCount = allItems.where((i) => i.type == ItemType.lost).length;
    final foundCount = allItems.where((i) => i.type == ItemType.found).length;

    return Row(
      children: [
        Expanded(
          child: _EntryCard(
            label: 'Lost Items',
            count: lostCount,
            icon: Icons.search_off_rounded,
            accentColor: CSColors.statusLost,
            tintColor: selectedType == ItemType.lost ? CSColors.surfaceLostTint : CSColors.statusLostTint,
            isSelected: selectedType == ItemType.lost,
            onTap: () => onSelectType(ItemType.lost),
          ),
        ),
        const SizedBox(width: CSSpacing.md),
        Expanded(
          child: _EntryCard(
            label: 'Found Items',
            count: foundCount,
            icon: Icons.volunteer_activism_rounded,
            accentColor: CSColors.statusFound,
            tintColor: selectedType == ItemType.found ? CSColors.surfaceFoundTint : CSColors.statusFoundTint,
            isSelected: selectedType == ItemType.found,
            onTap: () => onSelectType(ItemType.found),
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
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color tintColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(CSSpacing.md),
        decoration: BoxDecoration(
          color: tintColor,
          borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? accentColor : accentColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 0.5,
          ),
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
              isSelected ? 'tap to clear filter' : 'active reports',
              style: CSTypography.caption.copyWith(color: accentColor.withValues(alpha: 0.7)),
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
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
