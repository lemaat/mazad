import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../config/app_config.dart';
import '../theme/colors.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/listings/data/listing_repository.dart';
import '../../features/listings/presentation/listing_browse_screen.dart';
import '../../features/listings/presentation/live_listings_tab.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_tab.dart';
import '../../features/sell/data/sell_repository.dart';
import '../../features/sell/presentation/create_listing_screen.dart';
import '../../features/wallet/presentation/wallet_tab.dart';

class NavShell extends StatefulWidget {
  const NavShell({
    super.key,
    required this.authController,
    required this.listingRepository,
  });
  final AuthController authController;
  final ListingRepository listingRepository;

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> with WidgetsBindingObserver {
  int _index = 0;
  int _unreadCount = 0;
  int _feedRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.authController.isLoggedIn) _fetchUnreadCount();
    widget.authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (widget.authController.isLoggedIn) {
      _fetchUnreadCount();
    } else {
      if (mounted) setState(() => _unreadCount = 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.authController.isLoggedIn) {
      _fetchUnreadCount();
    }
  }

  Future<void> _fetchUnreadCount() async {
    final token = widget.authController.token;
    if (token == null) return;
    try {
      final repo = NotificationRepository(host: AppConfig.host, token: token);
      final count = await repo.fetchUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // best-effort
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              ListingBrowseScreen(
                controller: widget.authController,
                repository: widget.listingRepository,
                refreshToken: _feedRefreshToken,
              ),
              LiveListingsTab(
                repository: widget.listingRepository,
                authController: widget.authController,
              ),
              WalletTab(controller: widget.authController),
              widget.authController.isLoggedIn
                  ? NotificationsScreen(controller: widget.authController)
                  : _LoginPrompt(label: l10n.signInToSeeNotifications),
              ProfileTab(
                controller: widget.authController,
                listingRepository: widget.listingRepository,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onTabSelected,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: const Icon(Icons.explore),
                label: l10n.navFeed,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bolt_outlined),
                selectedIcon: const Icon(Icons.bolt),
                label: l10n.navLive,
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(Icons.account_balance_wallet),
                label: l10n.navWallet,
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _unreadCount > 0,
                  label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
                  child: const Icon(Icons.notifications_none_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: _unreadCount > 0,
                  label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
                  child: const Icon(Icons.notifications),
                ),
                label: l10n.navAlerts,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l10n.navProfile,
              ),
            ],
            indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
          ),
          floatingActionButton: _index == 0 && widget.authController.isLoggedIn
              ? FloatingActionButton(
                  onPressed: _openSellFlow,
                  tooltip: l10n.createListingTooltip,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  void _onTabSelected(int i) {
    setState(() => _index = i);
    // Refresh unread count when user navigates to the Alerts tab.
    if (i == 3 && widget.authController.isLoggedIn) _fetchUnreadCount();
  }

  Future<void> _openSellFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateListingScreen(
          repository: SellRepository(
            host: AppConfig.host,
            token: widget.authController.token!,
          ),
          listingRepository: widget.listingRepository,
          controller: widget.authController,
        ),
      ),
    );
    // Whether the flow finished with a new listing or was cancelled partway,
    // refresh the Feed so a newly created listing shows up immediately
    // instead of only appearing after a manual pull-to-refresh.
    if (mounted) setState(() => _feedRefreshToken++);
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: AppColors.neutralGray),
      ),
    );
  }
}
