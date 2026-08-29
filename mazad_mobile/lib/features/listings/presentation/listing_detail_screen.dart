import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../bidding/presentation/live_auction_screen.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../sell/data/sell_repository.dart';
import '../../wallet/data/wallet_repository.dart';
import '../data/listing_repository.dart';

String _fmtCurrency(int amount) =>
    'MRU ${amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    )}';

String _fmtDateTime(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
      '${pad(dt.hour)}:${pad(dt.minute)}';
}

/// Returns a formatted time-remaining string (e.g. "2d 3h", "5h 12m", "3m 45s").
/// Returns null if the target has already passed.
String? _fmtTimeLeftOrNull(DateTime target) {
  final diff = target.difference(DateTime.now());
  if (diff.isNegative) return null;
  if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
  if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  return '${diff.inMinutes}m ${diff.inSeconds.remainder(60)}s';
}


class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({
    super.key,
    required this.summary,
    required this.controller,
    required this.repository,
  });

  final ListingSummary summary;
  final AuthController controller;
  final ListingRepository repository;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  ListingDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _joiningAuction = false;
  bool _offeringSecondChance = false;
  bool _endingUnsold = false;
  bool _acceptingSecondChance = false;

  SellRepository get _sellRepo => SellRepository(
        host: AppConfig.host,
        token: widget.controller.token!,
      );

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.repository.fetchDetail(
        widget.summary.id,
        token: widget.controller.token,
      );
      if (!mounted) return;
      setState(() => _detail = detail);
    } on ListingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.couldNotReachServer);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToLiveAuction() async {
    if (_joiningAuction) return;
    setState(() => _joiningAuction = true);
    try {
      // 1. Ensure authenticated.
      if (!widget.controller.isLoggedIn) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              controller: widget.controller,
              onAuthenticated: () => Navigator.pop(context),
            ),
          ),
        );
        if (!widget.controller.isLoggedIn || !mounted) return;
      }

      // 2. Check for an existing active deposit on this listing.
      final walletRepo = WalletRepository(
        host: AppConfig.host,
        token: widget.controller.token!,
      );

      List<DepositInfo> deposits;
      try {
        deposits = await walletRepo.fetchDeposits(listingId: widget.summary.id);
      } on WalletException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        return;
      } on SocketException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReachServer)),
        );
        return;
      }

      // 3. If no deposit exists, prompt user to place one.
      if (deposits.isEmpty) {
        if (!mounted) return;
        final deposited = await _showDepositSheet(walletRepo);
        if (!deposited || !mounted) return;
      }

      // 3b. The server only flips status away from 'live' when
      // close_expired_auctions next runs, so a listing can still read
      // status == 'live' here well after its real auction_end has passed.
      // Opening the live room for one of those leaves it stuck waiting on
      // events that will never arrive. Catch that case before navigating.
      final endTime = _detail?.auctionEnd ?? widget.summary.auctionEnd;
      if (endTime.isBefore(DateTime.now())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This auction's time has ended and it hasn't finished closing out yet — pull to refresh in a moment and try again.",
            ),
          ),
        );
        return;
      }

      // 4. Proceed to live auction.
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveAuctionScreen(
            listingId: widget.summary.id,
            authToken: widget.controller.token!,
            myBidderLabel:
                widget.controller.username ?? widget.controller.bidderNumber!,
            myBidderNumber: widget.controller.bidderNumber!,
            listingTitle: _detail?.title ?? widget.summary.title,
            categoryName: widget.summary.category.name,
            listingImageUrl: (_detail != null && _detail!.imageUrls.isNotEmpty)
                ? _detail!.imageUrls.first
                : widget.summary.primaryImageUrl,
            host: AppConfig.host,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _joiningAuction = false);
    }
  }

  Future<bool> _showDepositSheet(WalletRepository walletRepo) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DepositSheet(
        repository: walletRepo,
        listingId: widget.summary.id,
        listingTitle: _detail?.title ?? widget.summary.title,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.summary.status == 'live';
    final isScheduled = widget.summary.status == 'scheduled';
    final isPendingDecision = widget.summary.status == 'pending_seller_decision';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.summary.category.name, style: AppTypography.body),
        leading: const BackButton(),
        actions: [
          if (widget.controller.isLoggedIn)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FavoriteButton(
                listingId: widget.summary.id,
                isFavorited: _detail?.isFavorited ?? widget.summary.isFavorited,
                host: AppConfig.host,
                token: widget.controller.token!,
                size: 24,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: (isLive || isScheduled)
          ? _buildBottomBar(isLive)
          : isPendingDecision
              ? _buildDecisionBottomBar()
              : null,
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
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
            ElevatedButton(
              onPressed: _loadDetail,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    final price = d.currentPrice ?? d.startingPrice;
    final hasBids = d.currentPrice != null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: (widget.summary.status == 'live' ||
                widget.summary.status == 'scheduled' ||
                widget.summary.status == 'pending_seller_decision')
            ? 96
            : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.imageUrls.isNotEmpty) _buildImages(d.imageUrls),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow(d),
                const SizedBox(height: 16),
                Text(
                  d.title,
                  style: AppTypography.title.copyWith(
                    color: AppColors.neutralDark,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPriceCard(d, price, hasBids),
                const SizedBox(height: 20),
                _buildTimingCard(d),
                const SizedBox(height: 20),
                if (d.description.isNotEmpty) ...[
                  _buildSectionLabel(AppLocalizations.of(context)!.descriptionSectionLabel),
                  const SizedBox(height: 8),
                  Text(
                    d.description,
                    style: AppTypography.body.copyWith(color: AppColors.neutralGray),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildDepositNote(d),
                if (d.status == 'pending_seller_decision') ...[
                  const SizedBox(height: 20),
                  _buildDecisionPanel(d),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImages(List<String> urls) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: urls.length,
        separatorBuilder: (_, i) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            urls[i],
            width: 300,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, err, stack) => Container(
              width: 300,
              color: AppColors.primaryBlue.withValues(alpha: 0.07),
              child: const Icon(Icons.image_not_supported_outlined,
                  color: AppColors.neutralGray, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(ListingDetail d) {
    return Row(
      children: [
        _StatusChip(status: d.status),
        const SizedBox(width: 8),
        Text(
          d.category.name,
          style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
        ),
      ],
    );
  }

  Widget _buildPriceCard(ListingDetail d, int price, bool hasBids) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _priceRow(
            hasBids ? l10n.currentBid : l10n.startingPrice,
            _fmtCurrency(price),
            large: true,
          ),
          if (hasBids) ...[
            const SizedBox(height: 8),
            _priceRow(l10n.startingPrice, _fmtCurrency(d.startingPrice)),
          ],
          const SizedBox(height: 8),
          _priceRow(l10n.minimumIncrement, _fmtCurrency(d.minIncrement)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray)),
        Text(
          value,
          style: large
              ? AppTypography.title.copyWith(
                  color: AppColors.neutralDark, fontSize: 18)
              : AppTypography.body.copyWith(color: AppColors.neutralDark),
        ),
      ],
    );
  }

  Widget _buildTimingCard(ListingDetail d) {
    final l10n = AppLocalizations.of(context)!;
    final isLive = d.status == 'live';
    final isScheduled = d.status == 'scheduled';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _timingRow(l10n.auctionOpens, _fmtDateTime(d.auctionStart)),
          const SizedBox(height: 8),
          _timingRow(l10n.auctionCloses, _fmtDateTime(d.auctionEnd)),
          if (isLive) ...[
            const SizedBox(height: 8),
            _timingRow(
              l10n.timeRemaining,
              _fmtTimeLeftOrNull(d.auctionEnd) ?? l10n.timeEnded,
              highlight: true,
            ),
          ] else if (isScheduled) ...[
            const SizedBox(height: 8),
            _timingRow(
              '',
              _fmtTimeLeftOrNull(d.auctionStart) != null
                  ? l10n.startsIn(_fmtTimeLeftOrNull(d.auctionStart)!)
                  : l10n.timeHasStarted,
              highlight: true,
            ),
          ],
          const SizedBox(height: 8),
          _timingRow(
            l10n.softCloseWindow,
            l10n.softCloseWindowValue(d.softCloseWindowSeconds ~/ 60),
          ),
        ],
      ),
    );
  }

  Widget _timingRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray)),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: highlight ? AppColors.success : AppColors.neutralDark,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDepositNote(ListingDetail d) {
    if (d.status != 'live' && d.status != 'scheduled') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.depositNote,
              style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.label.copyWith(
        color: AppColors.neutralGray,
        letterSpacing: 0.5,
      ),
    );
  }

  Future<void> _offerSecondChance() async {
    setState(() => _offeringSecondChance = true);
    try {
      await _sellRepo.offerSecondChance(widget.summary.id);
      if (!mounted) return;
      await _loadDetail();
    } on SellException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReachServer)));
    } finally {
      if (mounted) setState(() => _offeringSecondChance = false);
    }
  }

  Future<void> _endUnsold() async {
    setState(() => _endingUnsold = true);
    try {
      await _sellRepo.endUnsold(widget.summary.id);
      if (!mounted) return;
      Navigator.pop(context);
    } on SellException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReachServer)));
    } finally {
      if (mounted) setState(() => _endingUnsold = false);
    }
  }

  Future<void> _acceptSecondChance() async {
    setState(() => _acceptingSecondChance = true);
    try {
      await _sellRepo.acceptSecondChance(widget.summary.id);
      if (!mounted) return;
      await _loadDetail();
    } on SellException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReachServer)));
    } finally {
      if (mounted) setState(() => _acceptingSecondChance = false);
    }
  }

  Widget? _buildDecisionBottomBar() {
    final d = _detail;
    if (d == null) return null;
    final myBidderNumber = widget.controller.bidderNumber;
    if (myBidderNumber == null) return null;

    final isSeller = d.sellerBidderNumber == myBidderNumber;
    final sale = d.saleInfo;
    final isRunnerUp = sale?.runnerUpBidderNumber == myBidderNumber;
    final secondChanceOffered = sale?.secondChanceDeadline != null;

    if (isSeller) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _endingUnsold ? null : _endUnsold,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _endingUnsold
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(AppLocalizations.of(context)!.endUnsoldButton, style: AppTypography.body.copyWith(color: AppColors.neutralGray)),
                  ),
                ),
              ),
              if (sale?.runnerUpBidderNumber != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _offeringSecondChance ? null : _offerSecondChance,
                      child: _offeringSecondChance
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textLight))
                          : Text(AppLocalizations.of(context)!.secondChanceButton),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (isRunnerUp && secondChanceOffered) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _acceptingSecondChance ? null : _acceptSecondChance,
              child: _acceptingSecondChance
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textLight))
                  : Text(AppLocalizations.of(context)!.acceptSecondChanceButton),
            ),
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildDecisionPanel(ListingDetail d) {
    final l10n = AppLocalizations.of(context)!;
    final myBidderNumber = widget.controller.bidderNumber;
    final sale = d.saleInfo;
    if (sale == null) return const SizedBox.shrink();

    final isSeller = d.sellerBidderNumber == myBidderNumber;
    final isRunnerUp = sale.runnerUpBidderNumber == myBidderNumber;
    final secondChanceOffered = sale.secondChanceDeadline != null;

    if (isSeller) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  l10n.auctionEndedDecisionRequired,
                  style: AppTypography.body.copyWith(color: AppColors.neutralDark, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _priceRow(l10n.winningBid, _fmtCurrency(sale.finalPrice)),
            if (sale.runnerUpBidderNumber != null) ...[
              const SizedBox(height: 8),
              _priceRow(l10n.runnerUpBidder, '#${sale.runnerUpBidderNumber}'),
            ],
            if (secondChanceOffered) ...[
              const SizedBox(height: 8),
              _priceRow(l10n.secondChanceDeadline, _fmtDateTime(sale.secondChanceDeadline!)),
            ],
          ],
        ),
      );
    }

    if (isRunnerUp) {
      if (!secondChanceOffered) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.sellerReviewingResult,
            style: AppTypography.body.copyWith(color: AppColors.neutralGray),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  l10n.secondChanceOfferedTitle,
                  style: AppTypography.body.copyWith(color: AppColors.neutralDark, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _priceRow(l10n.yourOfferPrice, _fmtCurrency(sale.finalPrice)),
            const SizedBox(height: 8),
            _priceRow(l10n.expiresLabel, _fmtDateTime(sale.secondChanceDeadline!)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomBar(bool isLive) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final l10n = AppLocalizations.of(context)!;
            if (!isLive) {
              return SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _fmtTimeLeftOrNull(widget.summary.auctionStart) != null
                        ? l10n.startsIn(_fmtTimeLeftOrNull(widget.summary.auctionStart)!)
                        : l10n.timeHasStarted,
                    style: AppTypography.body.copyWith(color: AppColors.neutralGray),
                  ),
                ),
              );
            }
            final loggedIn = widget.controller.isLoggedIn;
            return SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _joiningAuction ? null : _goToLiveAuction,
                child: _joiningAuction
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textLight,
                        ),
                      )
                    : Text(loggedIn ? l10n.joinAuction : l10n.signInToBid),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deposit bottom sheet
// ---------------------------------------------------------------------------

class _DepositSheet extends StatefulWidget {
  const _DepositSheet({
    required this.repository,
    required this.listingId,
    required this.listingTitle,
  });
  final WalletRepository repository;
  final String listingId;
  final String listingTitle;

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _bidController = TextEditingController();
  double? _availableBalance;
  bool _loadingBalance = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final b = await widget.repository.fetchBalance();
      if (mounted) setState(() => _availableBalance = b.availableBalance);
    } catch (_) {
      // Non-critical — the input form is still usable without it.
    } finally {
      if (mounted) setState(() => _loadingBalance = false);
    }
  }

  double? get _intendedBid {
    final text = _bidController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', ''));
  }

  double? get _requiredDeposit {
    final bid = _intendedBid;
    if (bid == null || bid <= 0) return null;
    return bid / 10;
  }

  Future<void> _submit() async {
    final deposit = _requiredDeposit;
    if (deposit == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.repository.createDeposit(
        listingId: widget.listingId,
        amountHeld: deposit,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on WalletException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.couldNotReachServer);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deposit = _requiredDeposit;
    final canSubmit = deposit != null && !_submitting;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.depositRequired,
            style: AppTypography.title.copyWith(
              color: AppColors.neutralDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.listingTitle,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          if (_loadingBalance)
            const SizedBox(
              height: 36,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_availableBalance != null)
            _buildBalanceRow(l10n),
          const SizedBox(height: 20),
          Text(
            l10n.yourIntendedMaxBid,
            style: AppTypography.label.copyWith(color: AppColors.neutralGray),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: 'MRU ',
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (deposit != null) ...[
            const SizedBox(height: 16),
            _buildDepositPreview(deposit, l10n),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.textLight,
                      ),
                    )
                  : Text(
                      deposit != null
                          ? l10n.placeDeposit('MRU ${deposit.toStringAsFixed(0)}')
                          : l10n.enterIntendedBidAbove,
                    ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
        ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.availableBalance,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
          ),
          Text(
            'MRU ${_availableBalance!.toStringAsFixed(0)}',
            style: AppTypography.body.copyWith(
              color: AppColors.neutralDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositPreview(double deposit, AppLocalizations l10n) {
    final bid = _intendedBid!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _previewRow(
            l10n.requiredDepositLabel,
            'MRU ${deposit.toStringAsFixed(0)}',
            AppColors.neutralDark,
          ),
          const SizedBox(height: 6),
          _previewRow(
            l10n.yourBidCeiling,
            'MRU ${bid.toStringAsFixed(0)}',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      'live' => (l10n.statusBadgeLive, AppColors.success, AppColors.surfaceWhite),
      'scheduled' => (
          l10n.statusBadgeUpcoming,
          AppColors.primaryBlue.withValues(alpha: 0.10),
          AppColors.primaryBlue
        ),
      'pending_seller_decision' => (
          l10n.statusBadgePending,
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning
        ),
      'ended_sold' => (
          l10n.statusBadgeSold,
          AppColors.error.withValues(alpha: 0.10),
          AppColors.error
        ),
      'ended_unsold' => (l10n.statusBadgeUnsold, AppColors.borderLight, AppColors.neutralGray),
      _ => (status.toUpperCase(), AppColors.borderLight, AppColors.neutralGray),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
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
