import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/cs_button.dart';
import '../../../core/widgets/cs_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../claims/data/claim_model.dart';
import '../../claims/data/claim_repository.dart';
import '../../items/data/item_repository.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      appBar: AppBar(
        title: const Text('My Activity'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CSColors.graphiteHairline, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: CSColors.inkBlack,
              unselectedLabelColor: CSColors.graphite,
              labelStyle: CSTypography.labelLarge,
              unselectedLabelStyle: CSTypography.labelMedium,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: CSColors.signalLimeDark,
                  width: 3,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'My Reports'),
                Tab(text: 'My Claims'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyReportsTab(),
          _MyClaimsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MyReportsTab extends ConsumerWidget {
  const _MyReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final uid = currentUser?.id ?? 'guest_user';
    final allItemsAsync = ref.watch(filteredItemsStreamProvider((type: null, category: null, query: '')));

    return allItemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: CSColors.textPrimary)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (items) {
        final userReports = items.where((i) => i.reportedByUid == uid).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: CSSpacing.screenPadding,
            vertical: CSSpacing.md,
          ),
          children: [
            if (currentUser?.isAnonymous ?? true) const _AuthGateBanner(),
            const SizedBox(height: CSSpacing.md),

            if (userReports.isEmpty)
              CSEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No reports yet',
                body: 'When you report a lost or found item, it will appear here with its current status.',
                actionLabel: 'Report an item',
                onAction: () {
                  context.push(AppConstants.kRouteReportItem);
                },
              )
            else
              ...userReports.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: CSSpacing.md),
                  child: CSItemCard(
                    item: item,
                    onTap: () {
                      context.push('/items/${item.id}');
                    },
                  ),
                ),
              ),

            const SizedBox(height: CSSpacing.md),
            const _StatusLegend(),
            const SizedBox(height: CSSpacing.xl),
          ],
        );
      },
    );
  }
}

class _MyClaimsTab extends ConsumerWidget {
  const _MyClaimsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final uid = currentUser?.id ?? 'guest_user';
    final claimsAsync = ref.watch(userClaimsStreamProvider(uid));

    return claimsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: CSColors.textPrimary)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (claims) {
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: CSSpacing.screenPadding,
            vertical: CSSpacing.md,
          ),
          children: [
            if (currentUser?.isAnonymous ?? true) const _AuthGateBanner(),
            const SizedBox(height: CSSpacing.md),

            if (claims.isEmpty)
              CSEmptyState(
                icon: Icons.task_alt_outlined,
                title: 'No claims submitted',
                body: 'When you submit a claim for an item you believe is yours, it will appear here with its approval status.',
                actionLabel: 'Browse campus items',
                onAction: () {
                  context.go('/home');
                },
              )
            else
              ...claims.map(
                (claim) => _ClaimItemCard(claim: claim),
              ),

            const SizedBox(height: CSSpacing.xl),
          ],
        );
      },
    );
  }
}

class _ClaimItemCard extends StatelessWidget {
  const _ClaimItemCard({required this.claim});
  final ClaimModel claim;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (claim.status) {
      case ClaimStatus.pending:
        statusColor = CSColors.warningOrange;
        break;
      case ClaimStatus.approved:
        statusColor = CSColors.accentLimeDark;
        break;
      case ClaimStatus.rejected:
        statusColor = CSColors.textMuted;
        break;
      case ClaimStatus.withdrawn:
        statusColor = CSColors.graphite;
        break;
    }

    return InkWell(
      onTap: () => context.push('/items/${claim.itemId}'),
      borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
      child: Container(
        margin: const EdgeInsets.only(bottom: CSSpacing.md),
        padding: const EdgeInsets.all(CSSpacing.spacing16),
        decoration: BoxDecoration(
          color: CSColors.surfaceCard,
          borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
          border: Border.all(color: CSColors.dividerLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CSStatusLabel(
                  text: claim.status.displayName.toUpperCase(),
                  color: statusColor,
                ),
                Text(
                  DateFormat('MMM d').format(claim.createdAt),
                  style: CSTypography.caption.copyWith(color: CSColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: CSSpacing.spacing12),
            Text(
              claim.itemTitle,
              style: CSTypography.headlineSmall.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Evidence submitted: "${claim.verificationEvidence}"',
              style: CSTypography.bodySmall.copyWith(
                color: CSColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AuthGateBanner extends StatelessWidget {
  const _AuthGateBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CSSpacing.md),
      decoration: BoxDecoration(
        color: CSColors.paperDark,
        borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
        border: Border.all(color: CSColors.graphiteHairline, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: CSColors.graphite,
          ),
          const SizedBox(width: CSSpacing.sm),
          Expanded(
            child: Text(
              'Sign in to sync your reports across devices.',
              style: CSTypography.bodySmall,
            ),
          ),
          const SizedBox(width: CSSpacing.sm),
          GestureDetector(
            onTap: () {
              context.go('/profile');
            },
            child: Text(
              'Profile',
              style: CSTypography.labelMedium.copyWith(
                color: CSColors.inkBlack,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: CSColors.signalLimeDark,
                decorationThickness: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CSSpacing.md),
      decoration: BoxDecoration(
        color: CSColors.paperDark,
        borderRadius: BorderRadius.circular(CSSpacing.radiusMd),
        border: Border.all(color: CSColors.graphiteHairline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item lifecycle',
            style: CSTypography.titleMedium,
          ),
          const SizedBox(height: CSSpacing.md),
          const _LegendRow(
            color: CSColors.statusLost,
            label: 'Active',
            description: 'Item is reported, no match yet.',
          ),
          const SizedBox(height: CSSpacing.sm),
          const _LegendRow(
            color: CSColors.statusClaimed,
            label: 'Claimed',
            description: 'A claim is pending review.',
          ),
          const SizedBox(height: CSSpacing.sm),
          const _LegendRow(
            color: CSColors.statusFound,
            label: 'Returned',
            description: 'Item has been returned to its owner.',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.description,
  });

  final Color color;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: CSSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CSTypography.labelLarge),
            Text(description, style: CSTypography.caption),
          ],
        ),
      ],
    );
  }
}
