import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_model.dart';
import '../../../core/widgets/cs_button.dart';
import '../../../core/widgets/cs_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../claims/data/claim_model.dart';
import '../../claims/data/claim_repository.dart';
import '../data/item_repository.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  void _showClaimDialog(BuildContext context, WidgetRef ref, ItemModel item) {
    final currentUser = ref.read(currentUserProvider);
    final evidenceController = TextEditingController();
    final contactController = TextEditingController(text: currentUser?.phoneNumber ?? '');
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CSColors.bgPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CSSpacing.radiusCard)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: CSSpacing.pageHorizontal,
                right: CSSpacing.pageHorizontal,
                top: CSSpacing.spacing24,
                bottom: MediaQuery.of(context).viewInsets.bottom + CSSpacing.spacing24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Submit Ownership Claim',
                            style: CSTypography.headlineSmall.copyWith(fontSize: 20),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: CSColors.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: CSSpacing.spacing8),
                    Text(
                      'Provide verifiable private details that only the true owner would know.',
                      style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                    ),
                    const SizedBox(height: CSSpacing.spacing16),

                    TextFormField(
                      controller: evidenceController,
                      maxLines: 4,
                      style: CSTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Private Verification Evidence *',
                        hintText: 'e.g. Serial number, lockscreen wallpaper, sticker labels, contents of pocket/bag...',
                        hintStyle: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                        filled: true,
                        fillColor: CSColors.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                          borderSide: const BorderSide(color: CSColors.dividerLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: CSSpacing.spacing16),

                    TextFormField(
                      controller: contactController,
                      style: CSTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Contact Phone or Campus Handle',
                        hintText: '+1 (555) 019-2834 or @student_handle',
                        hintStyle: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                        filled: true,
                        fillColor: CSColors.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                          borderSide: const BorderSide(color: CSColors.dividerLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: CSSpacing.spacing20),

                    CSPrimaryButton(
                      label: isSubmitting ? 'Submitting Claim...' : 'Submit Evidence for Review',
                      icon: Icons.verified_user_outlined,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final evidence = evidenceController.text.trim();
                              if (evidence.length < 8) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please provide more detailed verification evidence.'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                              });

                              final claim = ClaimModel(
                                id: 'clm_${DateTime.now().millisecondsSinceEpoch}',
                                itemId: item.id,
                                itemTitle: item.title,
                                claimantUid: currentUser?.id ?? 'guest_user',
                                claimantName: currentUser?.displayName ?? 'Anonymous Claimant',
                                claimantEmail: currentUser?.email ?? 'guest@campus.edu',
                                claimantContact: contactController.text.trim(),
                                verificationEvidence: evidence,
                                createdAt: DateTime.now(),
                              );

                              await ref.read(claimRepositoryProvider).submitClaim(claim);

                              // Update item status to claimed
                              await ref.read(itemRepositoryProvider).updateItem(
                                    item.copyWith(
                                      status: ItemStatus.claimed,
                                      claimedByUid: currentUser?.id,
                                    ),
                                  );

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: CSColors.accentLimeDark,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      'Claim submitted! Campus security/finder will review your evidence.',
                                      style: CSTypography.labelSmall.copyWith(
                                        color: CSColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));

    return Scaffold(
      backgroundColor: CSColors.bgPaper,
      appBar: AppBar(
        backgroundColor: CSColors.bgPaper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CSColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: CSColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item link copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: itemAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CSColors.textPrimary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading item: $err', style: CSTypography.bodyMedium),
        ),
        data: (item) {
          if (item == null) {
            return Center(
              child: Text('Item not found', style: CSTypography.headlineSmall),
            );
          }

          final isLost = item.type == ItemType.lost;
          final isClaimed = item.status == ItemStatus.claimed;
          final isReturned = item.status == ItemStatus.returned;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: CSSpacing.pageHorizontal,
                vertical: CSSpacing.spacing16,
              ),
              children: [
                // ─── Header: Status & Category ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CSStatusLabel(
                      text: isLost ? 'LOST ITEM' : 'FOUND ITEM',
                      color: isLost ? CSColors.warningOrange : CSColors.accentLimeDark,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CSColors.surfaceCard,
                        borderRadius: BorderRadius.circular(CSSpacing.radiusChip),
                        border: Border.all(color: CSColors.dividerLight),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: CSTypography.labelSmall.copyWith(
                          color: CSColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CSSpacing.spacing16),

                // ─── Item Title & Timestamp ────────────────────────────────────
                Text(
                  item.title,
                  style: CSTypography.headlineMedium.copyWith(fontSize: 28),
                ),
                const SizedBox(height: CSSpacing.spacing8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: CSColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Reported ${DateFormat('MMM d, y • h:mm a').format(item.reportedAt)}',
                      style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: CSSpacing.spacing20),

                // ─── Photo / Visual Placeholder ────────────────────────────────
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                    child: item.imageUrl!.startsWith('http')
                        ? Image.network(
                            item.imageUrl!,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : Image.file(
                            File(item.imageUrl!),
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                  )
                else
                  _buildPlaceholder(),
                const SizedBox(height: CSSpacing.spacing20),

                // ─── Location Card ─────────────────────────────────────────────
                Container(
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
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: isLost ? CSColors.warningOrange : CSColors.accentLimeDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Approximate Campus Location',
                            style: CSTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.locationLabel,
                        style: CSTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Exact coordinates are kept private for security and returned item integrity.',
                        style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CSSpacing.spacing20),

                // ─── Description Section ───────────────────────────────────────
                const CSSectionHeader(title: 'Description'),
                const SizedBox(height: CSSpacing.spacing12),
                Container(
                  padding: const EdgeInsets.all(CSSpacing.spacing16),
                  decoration: BoxDecoration(
                    color: CSColors.surfaceCard,
                    borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                    border: Border.all(color: CSColors.dividerLight),
                  ),
                  child: Text(
                    item.description,
                    style: CSTypography.bodyMedium.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: CSSpacing.spacing32),

                // ─── Action Buttons ────────────────────────────────────────────
                if (isReturned)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CSColors.surfaceCard,
                      borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                      border: Border.all(color: CSColors.accentLimeDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: CSColors.accentLimeDark),
                        const SizedBox(width: 8),
                        Text(
                          'This item has been returned to its owner.',
                          style: CSTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else if (isClaimed)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CSColors.surfaceCard,
                      borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                      border: Border.all(color: CSColors.warningOrange),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_top_outlined, color: CSColors.warningOrange),
                        const SizedBox(width: 8),
                        Text(
                          'A claim is currently pending review.',
                          style: CSTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else if (!isLost)
                  CSPrimaryButton(
                    label: 'Claim This Item',
                    icon: Icons.verified_user_outlined,
                    onPressed: () => _showClaimDialog(context, ref, item),
                  )
                else
                  CSSecondaryButton(
                    label: 'I Have Found This Item',
                    icon: Icons.volunteer_activism_outlined,
                    onPressed: () {
                      context.push(AppConstants.kRouteReportItem, extra: ItemType.found);
                    },
                  ),
                const SizedBox(height: CSSpacing.spacing32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: CSColors.surfaceCard,
        borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
        border: Border.all(color: CSColors.dividerLight),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, size: 64, color: CSColors.surfacePlaceholder),
      ),
    );
  }
}
