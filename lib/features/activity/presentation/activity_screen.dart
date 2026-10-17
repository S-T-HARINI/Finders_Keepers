import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/widgets/cs_card.dart';

/// My Activity Screen — User's reports and claims
///
/// Phase 1: Polished, intentional empty state with clear CTAs.
/// Phase 2: Populated with user's Firestore items (auth-gated).
///
/// Design: Tabbed view (My Reports | My Claims) with empty states
/// that communicate purpose rather than absence.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
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
        children: [
          _MyReportsTab(),
          _MyClaimsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// My Reports tab — empty state (Phase 1)
class _MyReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Auth gate notice
          _AuthGateBanner(),
          const SizedBox(height: CSSpacing.lg),

          // Empty state
          CSEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No reports yet',
            body:
                'When you report a lost or found item, it will appear here with its current status.',
            actionLabel: 'Report an item',
            onAction: () {
              // Phase 2: navigate to report flow
            },
          ),

          // Status legend
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CSSpacing.screenPadding,
            ),
            child: _StatusLegend(),
          ),
          const SizedBox(height: CSSpacing.xl),
        ],
      ),
    );
  }
}

/// My Claims tab — empty state (Phase 1)
class _MyClaimsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _AuthGateBanner(),
          const SizedBox(height: CSSpacing.lg),
          CSEmptyState(
            icon: Icons.task_alt_outlined,
            title: 'No claims submitted',
            body:
                'When you submit a claim for an item you believe is yours, it will appear here with its approval status.',
            actionLabel: 'Browse found items',
            onAction: () {
              // Phase 2: navigate to explore
            },
          ),
          const SizedBox(height: CSSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Banner shown when user is not signed in
class _AuthGateBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(CSSpacing.screenPadding),
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
              'Sign in to manage your reports and claims.',
              style: CSTypography.bodySmall,
            ),
          ),
          const SizedBox(width: CSSpacing.sm),
          GestureDetector(
            onTap: () {
              // Phase 2: navigate to sign-in
            },
            child: Text(
              'Sign in',
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

/// Status legend explaining the item lifecycle
class _StatusLegend extends StatelessWidget {
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
