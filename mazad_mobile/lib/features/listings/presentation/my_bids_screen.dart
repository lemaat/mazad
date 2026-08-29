import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../orders/presentation/order_tracking_screen.dart';
import '../data/bid_repository.dart';
import '../data/listing_repository.dart';

String _fmtCurrency(int amount) =>
    'MRU ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

String _timeLeft(DateTime target, AppLocalizations l10n) {
  final diff = target.difference(DateTime.now());
  if (diff.isNegative) return l10n.timeEnded;
  if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours.remainder(24)}h left';
  if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
  return '${diff.inMinutes}m left';
}

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({
    super.key,
    required this.repository,
    required this.controller,
    required this.listingRepository,
  });
  final BidRepository repository;
  final AuthController controller;
  final ListingRepository listingRepository;

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  List<MyBid>? _bids;
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
      final result = await widget.repository.fetchMyBids(widget.controller.token!);
      if (mounted) setState(() => _bids = result);
    } on BidException catch (e) {
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
      appBar: AppBar(
        title: Text(l10n.myBids, style: AppTypography.body),
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
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTypography.body.copyWith(color: AppColors.neutralGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    final bids = _bids ?? [];
    if (bids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gavel_outlined, size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(l10n.noPlacedBids,
                  style: AppTypography.body.copyWith(color: AppColors.neutralGray),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Split into active (live/scheduled) and ended
    final active = bids.where((b) => b.listingStatus == 'live' || b.listingStatus == 'scheduled').toList();
    final ended = bids.where((b) => b.listingStatus != 'live' && b.listingStatus != 'scheduled').toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (active.isNotEmpty) ...[
            _SectionHeader(label: l10n.activeAuctions),
            ...active.map((b) => _BidCard(bid: b, controller: widget.controller, listingRepository: widget.listingRepository)),
          ],
          if (ended.isNotEmpty) ...[
            _SectionHeader(label: l10n.pastAuctions),
            ...ended.map((b) => _BidCard(bid: b, controller: widget.controller, listingRepository: widget.listingRepository)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(label,
            style: AppTypography.label.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8)),
      );
}

class _BidCard extends StatelessWidget {
  const _BidCard({required this.bid, required this.controller, required this.listingRepository});
  final MyBid bid;
  final AuthController controller;
  final ListingRepository listingRepository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isLive = bid.listingStatus == 'live';

    late final String indicator;
    late final Color indicatorColor;

    switch (bid.listingStatus) {
      case 'ended_sold':
        if (bid.isLeading) {
          indicator = l10n.indicatorWon;
          indicatorColor = AppColors.success;
        } else {
          indicator = l10n.indicatorLost;
          indicatorColor = AppColors.error;
        }
      case 'ended_unsold':
        indicator = l10n.indicatorNotSold;
        indicatorColor = AppColors.neutralGray;
      case 'pending_seller_decision':
        indicator = l10n.indicatorAwaitingSeller;
        indicatorColor = AppColors.warning;
      default:
        // live / scheduled
        if (bid.isLeading) {
          indicator = l10n.indicatorLeading;
          indicatorColor = AppColors.success;
        } else {
          indicator = l10n.indicatorOutbid;
          indicatorColor = AppColors.error;
        }
    }

    final borderColor = switch (bid.listingStatus) {
      'ended_sold' => bid.isLeading ? AppColors.success : AppColors.error,
      'ended_unsold' => AppColors.borderLight,
      'pending_seller_decision' => AppColors.warning,
      _ => bid.isLeading ? AppColors.success : AppColors.error,
    };

    final isWon = bid.listingStatus == 'ended_sold' && bid.isLeading;
    return GestureDetector(
      onTap: isWon
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(
                    listingId: bid.listingId,
                    listingTitle: bid.listingTitle,
                    isBuyerView: true,
                    controller: controller,
                    repository: listingRepository,
                  ),
                ),
              )
          : null,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bid.listingTitle,
                    style: AppTypography.body.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(width: 8),
              _Pill(label: indicator, color: indicatorColor),
            ],
          ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.myBidLabel,
                        style: AppTypography.label.copyWith(
                            color: cs.onSurfaceVariant, fontSize: 10)),
                    Text(_fmtCurrency(bid.myAmount),
                        style: AppTypography.body.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                if (bid.currentPrice != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.currentBidShortLabel,
                          style: AppTypography.label.copyWith(
                              color: cs.onSurfaceVariant, fontSize: 10)),
                      Text(_fmtCurrency(bid.currentPrice!),
                          style: AppTypography.body.copyWith(
                              color: bid.isLeading ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bid.categoryName,
                    style: AppTypography.caption.copyWith(color: cs.onSurfaceVariant)),
                Text(
                  isLive ? _timeLeft(bid.auctionEnd, l10n) : _timeLeft(bid.auctionEnd, l10n),
                  style: AppTypography.caption.copyWith(
                      color: isLive ? AppColors.success : cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: AppTypography.label.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            )),
      );
}
