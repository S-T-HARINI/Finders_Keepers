import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants/app_constants.dart';

/// Profile Screen — Account & settings shell
///
/// Phase 1: Settings list shell with clearly labeled placeholder sections.
/// Phase 2: Populate with real Firebase Auth user data.
///
/// Design: Personal, functional — not a social media profile.
/// Avatar area, account section, app settings, legal links.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () {
              // Phase 2: edit profile
            },
          ),
          const SizedBox(width: CSSpacing.xs),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Avatar / Identity area ───────────────────────────────────────
          _ProfileHero(),

          // ── Account section ───────────────────────────────────────────────
          const SizedBox(height: CSSpacing.sm),
          _SectionLabel(label: 'Account'),
          _SettingsItem(
            icon: Icons.person_outline_rounded,
            label: 'Personal information',
            subtitle: 'Name, email, phone number',
            onTap: () {},
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
          _SectionLabel(label: 'App'),
          _SettingsItem(
            icon: Icons.help_outline_rounded,
            label: 'How it works',
            subtitle: 'Guide to reporting and claiming',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.school_outlined,
            label: 'Campus settings',
            subtitle: 'Institution and campus area',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.color_lens_outlined,
            label: 'Appearance',
            subtitle: 'Theme preferences',
            onTap: () {},
          ),

          // ── Legal section ─────────────────────────────────────────────────
          const SizedBox(height: CSSpacing.sm),
          _SectionLabel(label: 'Legal & Info'),
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

          // ── Sign out ───────────────────────────────────────────────────────
          const SizedBox(height: CSSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CSSpacing.screenPadding,
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                // Phase 2: Firebase Auth sign out
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
          'A campus lost-and-found platform connecting students and staff.',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Hero area — avatar, name, campus, quick stats
class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: CSColors.paperDark,
              shape: BoxShape.circle,
              border: Border.all(color: CSColors.graphiteHairline),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: CSColors.graphite,
            ),
          ),
          const SizedBox(width: CSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest User',
                  style: CSTypography.headlineSmall,
                ),
                const SizedBox(height: CSSpacing.xs2),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: CSColors.graphite,
                    ),
                    const SizedBox(width: CSSpacing.xs2),
                    Text(
                      'Sign in to access your account',
                      style: CSTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: CSSpacing.sm),
                // Quick stats
                Row(
                  children: [
                    _MiniStat(count: '—', label: 'Reports'),
                    const SizedBox(width: CSSpacing.lg),
                    _MiniStat(count: '—', label: 'Claims'),
                    const SizedBox(width: CSSpacing.lg),
                    _MiniStat(count: '—', label: 'Returned'),
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

// ─────────────────────────────────────────────────────────────────────────────

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
    this.subtitle,
    required this.onTap,
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
