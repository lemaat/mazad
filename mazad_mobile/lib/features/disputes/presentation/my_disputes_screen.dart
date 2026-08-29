import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dispute_repository.dart';

class MyDisputesScreen extends StatefulWidget {
  const MyDisputesScreen({super.key, required this.controller});
  final AuthController controller;

  @override
  State<MyDisputesScreen> createState() => _MyDisputesScreenState();
}

class _MyDisputesScreenState extends State<MyDisputesScreen> {
  List<Dispute>? _disputes;
  bool _loading = true;
  String? _error;

  late final DisputeRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = DisputeRepository(
      host: AppConfig.host,
      token: widget.controller.token!,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.fetchMyDisputes();
      if (mounted) setState(() => _disputes = result);
    } on DisputeException catch (e) {
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
        title: Text(
          l10n.myDisputesTitle,
          style: AppTypography.body.copyWith(color: AppColors.neutralDark),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(
                _error!,
                style:
                    AppTypography.body.copyWith(color: AppColors.neutralGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    final disputes = _disputes ?? [];
    if (disputes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(
                l10n.noDisputes,
                style:
                    AppTypography.body.copyWith(color: AppColors.neutralGray),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: disputes.length,
        itemBuilder: (_, i) => _DisputeCard(dispute: disputes[i]),
      ),
    );
  }
}

// ── Dispute card ──────────────────────────────────────────────────────────────

String _categoryLabel(String category, AppLocalizations l10n) => switch (category) {
      'item_not_as_described' => l10n.disputeCategoryItemNotAsDescribed,
      'item_not_received' => l10n.disputeCategoryItemNotReceived,
      'payment_issue' => l10n.disputeCategoryPaymentIssue,
      'seller_unresponsive' => l10n.disputeCategorySellerUnresponsive,
      _ => l10n.disputeCategoryOther,
    };

String _fmtDate(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)}';
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({required this.dispute});
  final Dispute dispute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dispute.listingTitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.neutralDark,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _DisputeStatusChip(status: dispute.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _categoryLabel(dispute.category, l10n),
              style:
                  AppTypography.caption.copyWith(color: AppColors.neutralGray),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.disputeOtherParty(dispute.otherPartyBidderNumber),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.neutralGray),
                ),
                Text(
                  _fmtDate(dispute.createdAt),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.neutralGray),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _DisputeStatusChip extends StatelessWidget {
  const _DisputeStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      'open' => (
          l10n.disputeStatusOpen,
          AppColors.primaryBlue.withValues(alpha: 0.10),
          AppColors.primaryBlue,
        ),
      'under_review' => (
          l10n.disputeStatusUnderReview,
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning,
        ),
      'resolved' => (
          l10n.disputeStatusResolved,
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success,
        ),
      'dismissed' => (
          l10n.disputeStatusDismissed,
          AppColors.borderLight,
          AppColors.neutralGray,
        ),
      _ => (
          status.toUpperCase(),
          AppColors.borderLight,
          AppColors.neutralGray,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
