import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/wallet_repository.dart';
import 'wallet_screen.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key, required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoggedIn) {
          return WalletScreen(
            showBackButton: false,
            repository: WalletRepository(
              host: AppConfig.host,
              token: controller.token!,
            ),
          );
        }
        return _AuthGate(controller: controller);
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.wallet,
            style: AppTypography.title.copyWith(color: AppColors.neutralDark)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 56, color: AppColors.neutralGray),
              const SizedBox(height: 20),
              Text(
                l10n.signInToViewWallet,
                style: AppTypography.body.copyWith(color: AppColors.neutralDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.walletBalanceWillAppear,
                style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
