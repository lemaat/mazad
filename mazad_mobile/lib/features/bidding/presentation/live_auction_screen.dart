import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/typography.dart';
import '../data/auction_socket_service.dart';
import '../domain/auction_event.dart';
import '../domain/bid_event.dart';

String _formatCurrency(int amount) =>
    'MRU ${amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    )}';

enum _AuctionPhase {
  loading,
  loadFailed,
  live,
  calculatingResult,
  won,
  soldToOther,
  pendingDecision,
  endedUnsold,
}

class LiveAuctionScreen extends StatefulWidget {
  const LiveAuctionScreen({
    super.key,
    required this.listingId,
    required this.authToken,
    required this.myBidderLabel,
    required this.myBidderNumber,
    required this.listingTitle,
    required this.categoryName,
    this.listingImageUrl,
    this.initialRecentBids = const [],
    this.host = 'localhost',
    this.port = 8000,
  });

  final String listingId;
  final String authToken;
  /// Display label used to match bid_placed events (username or bidder_number).
  final String myBidderLabel;
  /// Raw bidder_number used to match winner fields in close events and REST sale.
  final String myBidderNumber;
  /// The real listing's title — shown in place of the old hardcoded placeholder.
  final String listingTitle;
  /// The real listing's category name — shown alongside "Deposit held".
  final String categoryName;
  /// The real listing's primary photo URL, if it has one.
  final String? listingImageUrl;
  /// Bid history from the REST listing detail (server's `top_bids`), so
  /// "Recent bids" isn't empty just because this device's socket wasn't
  /// connected yet when those bids were placed — e.g. after switching
  /// accounts on the same emulator and rejoining a room mid-auction.
  final List<BidEvent> initialRecentBids;
  final String host;
  final int port;

  @override
  State<LiveAuctionScreen> createState() => _LiveAuctionScreenState();
}

class _LiveAuctionScreenState extends State<LiveAuctionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AuctionSocketService _service;
  late StreamSubscription<AuctionEvent> _eventSub;
  late StreamSubscription<ConnectionStatus> _statusSub;
  late Timer _countdownTimer;

  int _currentAmount = 0;
  int _minIncrement = 50000;
  DateTime? _serverAuctionEnd;
  Duration _remaining = Duration.zero;
  String _leadingBidder = '';
  bool _isLeading = false;
  late List<BidEvent> _recentBids;
  _AuctionPhase _phase = _AuctionPhase.loading;
  ConnectionStatus _connStatus = ConnectionStatus.connecting;
  AuctionClosedEvent? _closeEvent;
  bool _isBidInFlight = false;
  String? _bidError;

  @override
  void initState() {
    super.initState();

    _recentBids = widget.initialRecentBids;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _service = AuctionSocketService(
      listingId: widget.listingId,
      myBidderLabel: widget.myBidderLabel,
      host: widget.host,
      authToken: widget.authToken,
      port: widget.port,
    );

    _statusSub = _service.connectionStatus.listen((s) {
      if (!mounted) return;
      setState(() => _connStatus = s);
    });

    _eventSub = _service.events.listen(_onEvent);
    _service.start();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final end = _serverAuctionEnd;
      if (end == null) return;
      final next = end.difference(DateTime.now());
      setState(() {
        _remaining = next.isNegative ? Duration.zero : next;
        if (_remaining == Duration.zero && _phase == _AuctionPhase.live) {
          _phase = _AuctionPhase.calculatingResult;
        }
      });
    });
  }

  void _onEvent(AuctionEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event) {
        case AuctionSnapshot():
          _currentAmount = event.currentPrice;
          _minIncrement = event.minIncrement;
          _serverAuctionEnd = event.auctionEnd;
          final rem = event.auctionEnd.difference(DateTime.now());
          _remaining = rem.isNegative ? Duration.zero : rem;
          // For already-closed listings, synthesize _closeEvent from REST data
          // so _EndStateCard sublines work without a live WS event.
          if (event.status != 'live') {
            _closeEvent = AuctionClosedEvent(
              status: event.status,
              winnerBidderNumber: event.buyerBidderNumber,
              winningAmount: event.finalPrice,
            );
            _pulseController.stop();
          }
          _phase = _phaseFromListingStatus(event.status, event.buyerBidderNumber);

        case BidPlacedEvent():
          _currentAmount = event.currentPrice;
          _serverAuctionEnd = event.auctionEnd;
          final rem = event.auctionEnd.difference(DateTime.now());
          _remaining = rem.isNegative ? Duration.zero : rem;
          _leadingBidder = event.bidderLabel;
          _isLeading = event.isCurrentUser;
          _bidError = null;
          _recentBids = [
            BidEvent(
              bidderNumber: event.bidderLabel,
              amount: event.currentPrice,
              timestamp: DateTime.now(),
              isCurrentUser: event.isCurrentUser,
            ),
            ..._recentBids,
          ].take(3).toList();

        case AuctionClosedEvent():
          _closeEvent = event;
          _phase = _phaseFromCloseEvent(event);
          _pulseController.stop();

        case SecondChanceOfferedEvent():
          // Runner-up is notified via ListingDetailScreen; nothing to show here.
          break;

        case ConnectionError():
          // Only regress to loadFailed from the initial loading state.
          // A mid-session reconnect error is already surfaced via ConnectionStatus.
          if (_phase == _AuctionPhase.loading) {
            _phase = _AuctionPhase.loadFailed;
          }
      }
    });
  }

  Future<void> _placeBid() async {
    if (_isBidInFlight) return;
    setState(() {
      _isBidInFlight = true;
      _bidError = null;
    });
    try {
      await _service.placeBid(_currentAmount + _minIncrement);
    } on PlaceBidException catch (e) {
      if (!mounted) return;
      setState(() => _bidError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bidError = AppLocalizations.of(context)!.networkError);
    } finally {
      if (mounted) setState(() => _isBidInFlight = false);
    }
  }

  _AuctionPhase _phaseFromListingStatus(String status, String? buyerBidderNumber) =>
      switch (status) {
        'ended_sold' when buyerBidderNumber == widget.myBidderNumber => _AuctionPhase.won,
        'ended_sold' => _AuctionPhase.soldToOther,
        'ended_unsold' => _AuctionPhase.endedUnsold,
        'pending_seller_decision' => _AuctionPhase.pendingDecision,
        _ => _AuctionPhase.live,
      };

  _AuctionPhase _phaseFromCloseEvent(AuctionClosedEvent e) => switch (e.status) {
        'ended_sold' when e.winnerBidderNumber == widget.myBidderNumber => _AuctionPhase.won,
        'ended_sold' => _AuctionPhase.soldToOther,
        'pending_seller_decision' => _AuctionPhase.pendingDecision,
        _ => _AuctionPhase.endedUnsold,
      };

  @override
  void dispose() {
    _pulseController.dispose();
    _eventSub.cancel();
    _statusSub.cancel();
    _countdownTimer.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _retry() {
    if (_phase == _AuctionPhase.loadFailed) {
      setState(() => _phase = _AuctionPhase.loading);
    }
    return _service.retry();
  }

  String _formatCountdown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _liveDot() => FadeTransition(
        opacity: _pulseAnim,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnded = _phase != _AuctionPhase.live && _phase != _AuctionPhase.loading;
    final isUrgent = !isEnded && _remaining.inSeconds <= 30 && _remaining.inSeconds > 0;
    final countdownColor = isUrgent ? AppColors.error : AppColors.textLight;

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          leading: Navigator.canPop(context) ? const BackButton() : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEnded) ...[_liveDot(), const SizedBox(width: 8)],
              Text(
                isEnded ? l10n.liveAuctionEndedLabel : l10n.liveAuctionLiveLabel,
                style: AppTypography.label.copyWith(
                  color: isEnded ? AppColors.secondaryText : AppColors.error,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsetsDirectional.only(end: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neutralGray,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.myBidderLabel,
                style: AppTypography.monoData.copyWith(color: AppColors.textLight),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_connStatus == ConnectionStatus.reconnecting)
              Container(
                width: double.infinity,
                color: AppColors.error.withAlpha(40),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l10n.reconnecting,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ),
            if (_connStatus == ConnectionStatus.disconnected)
              InkWell(
                onTap: _retry,
                child: Container(
                  width: double.infinity,
                  color: AppColors.error.withAlpha(60),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.connectionLostRetry,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textLight,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.surfaceDark,
                    child: widget.listingImageUrl != null
                        ? Image.network(
                            widget.listingImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              size: 56,
                              color: AppColors.secondaryText,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 56,
                            color: AppColors.secondaryText,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Countdown (visible while not ended)
                        if (!isEnded)
                          Row(
                            children: [
                              _liveDot(),
                              const SizedBox(width: 8),
                              Text(
                                _phase == _AuctionPhase.loading
                                    ? '--:--'
                                    : _formatCountdown(_remaining),
                                style: AppTypography.monoCountdown
                                    .copyWith(color: countdownColor),
                              ),
                              if (isUrgent) ...[
                                const SizedBox(width: 8),
                                Text(
                                  l10n.endingSoon,
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.error),
                                ),
                              ],
                              if (_phase == _AuctionPhase.calculatingResult) ...[
                                const SizedBox(width: 12),
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.calculatingResultLabel,
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.secondaryText),
                                ),
                              ],
                            ],
                          ),

                        const SizedBox(height: 20),

                        Text(
                          widget.listingTitle,
                          style: AppTypography.title.copyWith(
                            color: AppColors.textLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.categoryName}  ·  Deposit held',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.secondaryText),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          _currentAmount == 0 ? '---' : _formatCurrency(_currentAmount),
                          style: AppTypography.bidAmountDark,
                        ),

                        const SizedBox(height: 10),

                        if (_phase == _AuctionPhase.live ||
                            _phase == _AuctionPhase.loading)
                          _StatusLine(
                            isLeading: _isLeading,
                            leadingBidder: _leadingBidder,
                          ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_phase == _AuctionPhase.live &&
                                    _connStatus == ConnectionStatus.connected &&
                                    !_isBidInFlight)
                                ? _placeBid
                                : null,
                            child: _isBidInFlight
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _currentAmount == 0
                                        ? l10n.loadingBidButton
                                        : l10n.bidButton(_formatCurrency(_currentAmount + _minIncrement)),
                                  ),
                          ),
                        ),
                        if (_bidError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _bidError!,
                            style: AppTypography.caption.copyWith(color: AppColors.error),
                          ),
                        ],

                        const SizedBox(height: 24),

                        if (_phase == _AuctionPhase.loadFailed)
                          _LoadFailedCard(onRetry: _retry),

                        if (isEnded || _phase == _AuctionPhase.calculatingResult)
                          _EndStateCard(
                            phase: _phase,
                            closeEvent: _closeEvent,
                            myLabel: widget.myBidderLabel,
                          ),

                        if (_phase == _AuctionPhase.live) ...[
                          Text(
                            l10n.recentBids,
                            style: AppTypography.label.copyWith(
                              color: AppColors.secondaryText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_recentBids.isEmpty)
                            Text(
                              l10n.waitingForFirstBid,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.secondaryText),
                            )
                          else
                            ..._recentBids.map((bid) => _BidRow(bid: bid)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailedCard extends StatelessWidget {
  const _LoadFailedCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutralGray.withAlpha(60),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.couldntReachServer,
            style: AppTypography.label.copyWith(
              color: AppColors.error,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.checkConnectionRetry,
            style: AppTypography.body.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: AppTypography.body.copyWith(
                color: AppColors.accentYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndStateCard extends StatelessWidget {
  const _EndStateCard({
    required this.phase,
    required this.closeEvent,
    required this.myLabel,
  });

  final _AuctionPhase phase;
  final AuctionClosedEvent? closeEvent;
  final String myLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bgColor = phase == _AuctionPhase.won
        ? AppColors.success.withAlpha(30)
        : AppColors.neutralGray.withAlpha(60);

    final accentColor = phase == _AuctionPhase.won
        ? AppColors.success
        : AppColors.secondaryText;

    final headline = switch (phase) {
      _AuctionPhase.won => l10n.youWon,
      _AuctionPhase.soldToOther => l10n.auctionEndedHeadline,
      _AuctionPhase.pendingDecision => l10n.reserveNotMet,
      _AuctionPhase.endedUnsold => l10n.auctionEndedHeadline,
      _AuctionPhase.calculatingResult => l10n.calculatingResultHeadline,
      _ => '',
    };

    final e = closeEvent;
    final String? subline = e == null
        ? null
        : switch (phase) {
            _AuctionPhase.won =>
              l10n.finalPriceLabel(_formatCurrency(e.winningAmount ?? 0)),
            _AuctionPhase.soldToOther =>
              l10n.soldToOther(e.winnerBidderNumber ?? '', _formatCurrency(e.winningAmount ?? 0)),
            _AuctionPhase.pendingDecision => l10n.awaitingSellerDecision,
            _AuctionPhase.endedUnsold => l10n.noBidsMetReserve,
            _ => null,
          };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: AppTypography.label.copyWith(color: accentColor, letterSpacing: 1.0),
          ),
          if (subline != null) ...[
            const SizedBox(height: 6),
            Text(subline, style: AppTypography.body.copyWith(color: AppColors.textLight)),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.isLeading, required this.leadingBidder});

  final bool isLeading;
  final String leadingBidder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLeading) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 15, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            l10n.youreLeading,
            style: AppTypography.body.copyWith(color: AppColors.success),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.arrow_upward, size: 15, color: AppColors.error),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            leadingBidder.isEmpty
                ? l10n.noBidsYet
                : l10n.youveBeenOutbid(leadingBidder),
            style: AppTypography.body.copyWith(color: AppColors.error),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({required this.bid});

  final BidEvent bid;

  @override
  Widget build(BuildContext context) {
    final accent = bid.isCurrentUser ? AppColors.accentYellow : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            bid.bidderNumber,
            style: AppTypography.monoData.copyWith(color: accent ?? AppColors.secondaryText),
          ),
          const Spacer(),
          Text(
            _formatCurrency(bid.amount),
            style: AppTypography.monoData.copyWith(color: accent ?? AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
