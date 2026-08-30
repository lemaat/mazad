import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/typography.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/register_screen.dart';
import '../../about/presentation/about_screen.dart';
import '../../addresses/presentation/address_book_screen.dart';
import '../../disputes/presentation/my_disputes_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../kyc/presentation/kyc_screen.dart';
import '../../listings/data/bid_repository.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/presentation/my_bids_screen.dart';
import '../../sell/presentation/my_listings_screen.dart';
import '../../support/presentation/contact_support_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.controller,
    required this.listingRepository,
  });
  final AuthController controller;
  final ListingRepository listingRepository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => controller.isLoggedIn
          ? _LoggedInProfile(controller: controller, listingRepository: listingRepository)
          : _GuestProfile(controller: controller),
    );
  }
}

// ── Logged-in ─────────────────────────────────────────────────────────────────

class _LoggedInProfile extends StatelessWidget {
  const _LoggedInProfile({required this.controller, required this.listingRepository});
  final AuthController controller;
  final ListingRepository listingRepository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeCtrl = ThemeControllerProvider.of(context);
    final localeCtrl = LocaleControllerProvider.of(context);
    final name = controller.username?.isNotEmpty == true
        ? controller.username!
        : controller.bidderNumber ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile, style: AppTypography.title),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AvatarCard(name: name, bidderNumber: controller.bidderNumber ?? ''),
          const SizedBox(height: 24),
          _SectionLabel(l10n.sectionTrading),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _NavTile(
              icon: Icons.storefront_outlined,
              label: l10n.myListings,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyListingsScreen(
                    repository: listingRepository,
                    token: controller.token!,
                    controller: controller,
                  ),
                ),
              ),
            ),
            _NavTile(
              icon: Icons.gavel_outlined,
              label: l10n.myBids,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyBidsScreen(
                    repository: BidRepository(host: AppConfig.host),
                    controller: controller,
                    listingRepository: listingRepository,
                  ),
                ),
              ),
            ),
            _NavTile(
              icon: Icons.favorite_border,
              label: l10n.saved,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritesScreen(controller: controller),
                ),
              ),
            ),
            _NavTile(
              icon: Icons.location_on_outlined,
              label: l10n.addressBook,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddressBookScreen(controller: controller),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionLabel(l10n.sectionSupport),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _NavTile(
              icon: Icons.shield_outlined,
              label: l10n.myDisputes,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyDisputesScreen(controller: controller),
                ),
              ),
            ),
            _NavTile(
              icon: Icons.headset_mic_outlined,
              label: l10n.contactAndSupport,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactSupportScreen(),
                ),
              ),
            ),
            _NavTile(
              icon: Icons.info_outline,
              label: l10n.aboutUs,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionLabel(l10n.sectionPreferences),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _ThemeTile(controller: themeCtrl),
            _LanguageTile(controller: localeCtrl),
          ]),
          const SizedBox(height: 24),
          _SectionLabel(l10n.sectionAccount),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _NavTile(
              icon: _verificationIcon(controller.verificationTier),
              label: l10n.identityVerification,
              trailing: _verificationBadge(l10n, controller.verificationTier),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KycScreen(controller: controller),
                ),
              ),
            ),
            _ActionTile(
              icon: Icons.logout,
              label: l10n.signOut,
              color: AppColors.error,
              onTap: () => _confirmSignOut(context),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signOutDialogTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.signOut,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.logout();
  }
}

IconData _verificationIcon(String tier) {
  return switch (tier) {
    'id_verified' => Icons.verified_user_outlined,
    'phone_verified' => Icons.phone_android_outlined,
    _ => Icons.badge_outlined,
  };
}

Widget _verificationBadge(AppLocalizations l10n, String tier) {
  return switch (tier) {
    'id_verified' => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 16),
        const SizedBox(width: 4),
        Text(l10n.verifiedBadge, style: const TextStyle(color: AppColors.success, fontSize: 12)),
        const SizedBox(width: 4),
      ]),
    'pending' => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 16),
        const SizedBox(width: 4),
        Text(l10n.pendingBadge, style: const TextStyle(color: AppColors.warning, fontSize: 12)),
        const SizedBox(width: 4),
      ]),
    _ => const Icon(Icons.chevron_right, color: AppColors.neutralGray),
  };
}

// ── Guest ─────────────────────────────────────────────────────────────────────

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeCtrl = ThemeControllerProvider.of(context);
    final localeCtrl = LocaleControllerProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile, style: AppTypography.title),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel(l10n.sectionPreferences),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _ThemeTile(controller: themeCtrl),
            _LanguageTile(controller: localeCtrl),
          ]),
          const SizedBox(height: 24),
          _AuthButtons(controller: controller),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.name, required this.bidderNumber});
  final String name;
  final String bidderNumber;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.title
                  .copyWith(color: AppColors.textLight, fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.body.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(bidderNumber,
                    style: AppTypography.caption
                        .copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: AppTypography.label.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: children
            .expand((w) => [
                  w,
                  if (w != children.last)
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                ])
            .toList(),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (_, mode, _) {
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return SwitchListTile(
          value: isDark,
          onChanged: (on) =>
              controller.setMode(on ? ThemeMode.dark : ThemeMode.light),
          secondary: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: AppColors.primaryBlue,
          ),
          title: Text(l10n.darkMode,
              style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurface)),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.controller});
  final LocaleController controller;

  String _currentLabel(AppLocalizations l10n) {
    final code = controller.value?.languageCode;
    return switch (code) {
      'fr' => l10n.languageFrench,
      'ar' => l10n.languageArabic,
      _ => l10n.languageEnglish,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (locale: const Locale('en'), label: l10n.languageEnglish),
      (locale: const Locale('fr'), label: l10n.languageFrench),
      (locale: const Locale('ar'), label: l10n.languageArabic),
    ];
    return ValueListenableBuilder<Locale?>(
      valueListenable: controller,
      builder: (context, _, _) {
        final cs = Theme.of(context).colorScheme;
        return ListTile(
          leading: const Icon(Icons.language_outlined, color: AppColors.primaryBlue),
          title: Text(l10n.languageLabel,
              style: AppTypography.body.copyWith(color: cs.onSurface)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_currentLabel(l10n),
                  style: AppTypography.body.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
          onTap: () => _showPicker(context, options),
        );
      },
    );
  }

  void _showPicker(BuildContext context, List<({Locale locale, String label})> options) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final opt in options)
              ListTile(
                title: Text(opt.label, style: AppTypography.body),
                trailing: controller.value?.languageCode == opt.locale.languageCode ||
                        (controller.value == null && opt.locale.languageCode == 'en')
                    ? const Icon(Icons.check, color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  controller.setLocale(opt.locale);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(label, style: AppTypography.body.copyWith(color: cs.onSurface)),
      trailing: trailing ?? Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.neutralDark,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTypography.body.copyWith(color: color)),
      onTap: onTap,
    );
  }
}

class _AuthButtons extends StatelessWidget {
  const _AuthButtons({required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                controller: controller,
                onAuthenticated: () => Navigator.pop(context),
              ),
            ),
          ),
          child: Text(l10n.signIn),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterScreen(
                controller: controller,
                onAuthenticated: () => Navigator.pop(context),
              ),
            ),
          ),
          child: Text(l10n.createAccount),
        ),
      ],
    );
  }
}
