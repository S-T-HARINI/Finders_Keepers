import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/cs_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_model.dart';
import '../../claims/data/claim_repository.dart';
import '../../items/data/item_repository.dart';

/// Profile Screen — Account & Settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSignInDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController(text: 'alex.chen@campus.edu');
    final passwordController = TextEditingController(text: 'password123');
    final campusIdController = TextEditingController(text: 'STU-94821');
    bool isRegistering = false;
    bool isLoading = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CSColors.bgPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CSSpacing.radiusCard)),
      ),
      builder: (dialogContext) {
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
                            isRegistering ? 'Register Campus Account' : 'Sign in to Campus Account',
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
                      'Use your verified student or staff email to sync reports and verify claims.',
                      style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                    ),
                    const SizedBox(height: CSSpacing.spacing16),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: CSTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Campus Email',
                        filled: true,
                        fillColor: CSColors.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                          borderSide: const BorderSide(color: CSColors.dividerLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: CSSpacing.spacing12),

                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: CSTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: CSColors.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                          borderSide: const BorderSide(color: CSColors.dividerLight),
                        ),
                      ),
                    ),

                    if (isRegistering) ...[
                      const SizedBox(height: CSSpacing.spacing12),
                      TextFormField(
                        controller: campusIdController,
                        style: CSTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Student / Staff ID',
                          filled: true,
                          fillColor: CSColors.surfaceCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                            borderSide: const BorderSide(color: CSColors.dividerLight),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: CSSpacing.spacing20),

                    CSPrimaryButton(
                      label: isLoading
                          ? 'Please wait...'
                          : (isRegistering ? 'Create Campus Account' : 'Sign in'),
                      icon: isRegistering ? Icons.person_add_outlined : Icons.login_outlined,
                      onPressed: isLoading
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final pass = passwordController.text.trim();

                              if (email.isEmpty || pass.isEmpty) return;

                              setModalState(() => isLoading = true);

                              try {
                                if (isRegistering) {
                                  await ref.read(authRepositoryProvider).registerWithEmailAndPassword(
                                        email: email,
                                        password: pass,
                                        displayName: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
                                        campusId: campusIdController.text.trim(),
                                      );
                                } else {
                                  await ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, pass);
                                }

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: CSColors.accentLimeDark,
                                      content: Text(
                                        'Welcome, ${email.split('@').first}!',
                                        style: CSTypography.labelSmall.copyWith(
                                          color: CSColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                    ),
                    const SizedBox(height: CSSpacing.spacing12),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            isRegistering = !isRegistering;
                          });
                        },
                        child: Text(
                          isRegistering
                              ? 'Already have an account? Sign in'
                              : "Don't have an account? Register here",
                          style: CSTypography.bodySmall.copyWith(
                            color: CSColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
    final user = ref.watch(currentUserProvider);
    final uid = user?.id ?? 'guest_user';

    final itemsAsync = ref.watch(filteredItemsStreamProvider((type: null, category: null, query: '')));
    final claimsAsync = ref.watch(userClaimsStreamProvider(uid));

    final int userReportCount = itemsAsync.valueOrNull?.where((i) => i.reportedByUid == uid).length ?? 0;
    final int userClaimsCount = claimsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Account Settings',
            onPressed: () => _showSignInDialog(context, ref),
          ),
          const SizedBox(width: CSSpacing.xs),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Avatar / Identity area ───────────────────────────────────────
          _ProfileHero(
            user: user,
            reportCount: userReportCount,
            claimsCount: userClaimsCount,
            onSignInTap: () => _showSignInDialog(context, ref),
          ),

          // ── Account section ───────────────────────────────────────────────
          const SizedBox(height: CSSpacing.sm),
          const _SectionLabel(label: 'Account'),
          _SettingsItem(
            icon: Icons.person_outline_rounded,
            label: 'Personal information',
            subtitle: user != null ? '${user.displayName} • ${user.email}' : 'Name, email, phone number',
            onTap: () => _showSignInDialog(context, ref),
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            subtitle: 'Alerts for matches and claims',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.shield_outlined,
            label: 'Privacy',
            subtitle: 'Location precision, data sharing',
            onTap: () {},
          ),

          // ── App section ───────────────────────────────────────────────────
          const SizedBox(height: CSSpacing.sm),
          const _SectionLabel(label: 'App'),
          _SettingsItem(
            icon: Icons.help_outline_rounded,
            label: 'How it works',
            subtitle: 'Guide to reporting and claiming',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.school_outlined,
            label: 'Campus settings',
            subtitle: 'Central University Main Campus',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.color_lens_outlined,
            label: 'Appearance',
            subtitle: 'Campus Signal (Warm Ivory)',
            onTap: () {},
          ),

          // ── Legal section ─────────────────────────────────────────────────
          const SizedBox(height: CSSpacing.sm),
          const _SectionLabel(label: 'Legal & Info'),
          _SettingsItem(
            icon: Icons.description_outlined,
            label: 'Terms of service',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy policy',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.info_outline_rounded,
            label: 'About',
            subtitle: 'Version ${AppConstants.appVersion}',
            onTap: () => _showAbout(context),
          ),

          // ── Sign out / Sign in ─────────────────────────────────────────────
          const SizedBox(height: CSSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CSSpacing.screenPadding,
            ),
            child: user?.isAnonymous ?? true
                ? CSPrimaryButton(
                    label: 'Sign In / Register',
                    icon: Icons.login_outlined,
                    onPressed: () => _showSignInDialog(context, ref),
                  )
                : OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signed out.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CSColors.error,
                      side: const BorderSide(color: CSColors.error),
                      minimumSize: const Size(double.infinity, CSSpacing.touchTarget),
                    ),
                  ),
          ),

          const SizedBox(height: CSSpacing.xxl),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: '© 2026 Campus Tech. MIT License.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Finders Keepers — A production-quality campus lost-and-found mobile platform built with Flutter and the Campus Signal design system.',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.reportCount,
    required this.claimsCount,
    required this.onSignInTap,
  });

  final UserModel? user;
  final int reportCount;
  final int claimsCount;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    final isGuest = user?.isAnonymous ?? true;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        CSSpacing.screenPadding,
        CSSpacing.lg,
        CSSpacing.screenPadding,
        CSSpacing.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CSColors.graphiteHairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isGuest ? CSColors.paperDark : CSColors.accentLime,
              shape: BoxShape.circle,
              border: Border.all(color: CSColors.graphiteHairline),
            ),
            child: Icon(
              isGuest ? Icons.person_rounded : Icons.verified_user,
              size: 32,
              color: isGuest ? CSColors.graphite : CSColors.textPrimary,
            ),
          ),
          const SizedBox(width: CSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Guest User',
                  style: CSTypography.headlineSmall,
                ),
                const SizedBox(height: CSSpacing.xs2),
                if (isGuest)
                  GestureDetector(
                    onTap: onSignInTap,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: CSColors.graphite,
                        ),
                        const SizedBox(width: CSSpacing.xs2),
                        Text(
                          'Sign in to access your account',
                          style: CSTypography.caption.copyWith(
                            color: CSColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '${user?.role.displayName ?? "Student"} • ${user?.campusId ?? "ID-VERIFIED"}',
                    style: CSTypography.caption.copyWith(color: CSColors.textMuted),
                  ),
                const SizedBox(height: CSSpacing.sm),
                // Quick stats
                Row(
                  children: [
                    _MiniStat(count: '$reportCount', label: 'Reports'),
                    const SizedBox(width: CSSpacing.lg),
                    _MiniStat(count: '$claimsCount', label: 'Claims'),
                    const SizedBox(width: CSSpacing.lg),
                    const _MiniStat(count: '0', label: 'Returned'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.count, required this.label});
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: CSTypography.headlineSmall),
        Text(label, style: CSTypography.caption),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CSSpacing.screenPadding,
        CSSpacing.sm,
        CSSpacing.screenPadding,
        CSSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: CSTypography.labelSmall.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CSSpacing.screenPadding,
          vertical: CSSpacing.listItemVPadding,
        ),
        child: Row(
          children: [
            Icon(icon, size: CSSpacing.iconMd, color: CSColors.inkSecondary),
            const SizedBox(width: CSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: CSTypography.titleMedium),
                  if (subtitle != null)
                    Text(subtitle!, style: CSTypography.caption),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: CSColors.graphiteLight,
            ),
          ],
        ),
      ),
    );
  }
}
