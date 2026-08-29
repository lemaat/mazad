import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/wallet_repository.dart';

String _fmtAmount(double v) {
  final s = v.toStringAsFixed(0);
  return 'MRU ${s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    required this.repository,
    this.showBackButton = true,
  });
  final WalletRepository repository;
  final bool showBackButton;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletBalance? _balance;
  List<DepositInfo> _deposits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.fetchBalance(),
        widget.repository.fetchDeposits(),
      ]);
      if (!mounted) return;
      setState(() {
        _balance = results[0] as WalletBalance;
        _deposits = results[1] as List<DepositInfo>;
      });
    } on WalletException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.wallet,
            style: AppTypography.body.copyWith(color: AppColors.neutralDark)),
        leading: widget.showBackButton ? const BackButton() : null,
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(l10n)
              : _buildContent(l10n),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.neutralGray),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.body.copyWith(color: AppColors.neutralGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final b = _balance!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildBalanceCard(b, l10n),
          const SizedBox(height: 28),
          Text(
            l10n.activeDeposits,
            style: AppTypography.label
                .copyWith(color: AppColors.neutralGray, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          if (_deposits.isEmpty)
            _buildEmptyDeposits(l10n)
          else
            ..._deposits.map((d) => _buildDepositRow(d, l10n)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(WalletBalance b, AppLocalizations l10n) {
    final held = b.balance - b.availableBalance;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalBalance,
            style: AppTypography.caption.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 8),
          Text(
            _fmtAmount(b.balance),
            style: AppTypography.title.copyWith(
              color: AppColors.textLight,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0x33FFFFFF)),
          const SizedBox(height: 12),
          _cardRow(l10n.available, _fmtAmount(b.availableBalance), AppColors.textLight),
          const SizedBox(height: 8),
          _cardRow(l10n.inDeposits, _fmtAmount(held), AppColors.accentYellow),
        ],
      ),
    );
  }

  Widget _cardRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.secondaryText)),
        Text(
          value,
          style: AppTypography.body
              .copyWith(color: valueColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyDeposits(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          l10n.noActiveDeposits,
          style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDepositRow(DepositInfo d, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline,
                color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.listingTitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.neutralDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.bidCeilingLabel(_fmtAmount(d.bidCeiling)),
                  style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _fmtAmount(d.amountHeld),
            style: AppTypography.body.copyWith(
              color: AppColors.neutralDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
