import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../data/listing_repository.dart';
import 'listing_detail_screen.dart';

class LiveListingsTab extends StatefulWidget {
  const LiveListingsTab({
    super.key,
    required this.repository,
    required this.authController,
  });
  final ListingRepository repository;
  final AuthController authController;

  @override
  State<LiveListingsTab> createState() => _LiveListingsTabState();
}

class _LiveListingsTabState extends State<LiveListingsTab> {
  List<ListingSummary>? _listings;
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
      final result = await widget.repository.fetchListings(
        status: 'live,scheduled',
        token: widget.authController.token,
      );
      if (!mounted) return;
      setState(() => _listings = result);
    } on ListingException catch (e) {
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
        title: Text(l10n.liveAuctions, style: AppTypography.title),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
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
              Text(_error!,
                  style:
                      AppTypography.body.copyWith(color: AppColors.neutralGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final live = (_listings ?? [])
        .where((l) => l.status == 'live')
        .toList();
    final scheduled = (_listings ?? [])
        .where((l) => l.status == 'scheduled')
        .toList();

    if (live.isEmpty && scheduled.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_outlined,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(l10n.noLiveOrUpcomingAuctions,
                  style:
                      AppTypography.body.copyWith(color: AppColors.neutralGray),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (live.isNotEmpty) ...[
            _SectionHeader(label: l10n.liveNow, color: AppColors.success),
            ...live.map((l) => _LiveCard(
                  listing: l,
                  host: widget.authController.isLoggedIn ? widget.repository.host : null,
                  token: widget.authController.token,
                  onTap: () => _openDetail(l),
                )),
          ],
          if (scheduled.isNotEmpty) ...[
            _SectionHeader(label: l10n.comingUp, color: AppColors.primaryBlue),
            ...scheduled.map((l) => _LiveCard(
                  listing: l,
                  host: widget.authController.isLoggedIn ? widget.repository.host : null,
                  token: widget.authController.token,
                  onTap: () => _openDetail(l),
                )),
          ],
        ],
      ),
    );
  }

  void _openDetail(ListingSummary listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(
          summary: listing,
          controller: widget.authController,
          repository: widget.repository,
        ),
      ),
    );
  }
}

class _LiveThumbnail extends StatelessWidget {
  const _LiveThumbnail({required this.url, required this.isLive});
  final String? url;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? AppColors.success : AppColors.primaryBlue;
    final placeholder = Container(
      width: 56,
      height: 84,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(11),
          bottomLeft: Radius.circular(11),
        ),
      ),
      child: Icon(Icons.image_outlined, color: accent.withValues(alpha: 0.4), size: 22),
    );
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(11),
        bottomLeft: Radius.circular(11),
      ),
      child: Image.network(
        url!,
        width: 56,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.label.copyWith(
                color: AppColors.neutralGray, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.listing,
    required this.onTap,
    this.host,
    this.token,
  });
  final ListingSummary listing;
  final VoidCallback onTap;
  final String? host;
  final String? token;

  String _fmtDuration(Duration diff) {
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    return '${diff.inMinutes}m ${diff.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Same staleness caveat as ListingCard: status stays 'live' server-side
    // until close_expired_auctions next runs, even past auction_end — so
    // treat a listing whose end time has already passed as no longer live
    // rather than showing green "still live" styling next to "Ended" text.
    final isLive = listing.status == 'live' &&
        !listing.auctionEnd.isBefore(DateTime.now());
    final price = listing.currentPrice ?? listing.startingPrice;
    final timeTarget = isLive ? listing.auctionEnd : listing.auctionStart;
    final diff = timeTarget.difference(DateTime.now());

    String timeLabel;
    if (listing.status == 'live' && !isLive) {
      timeLabel = l10n.timeEnded;
    } else if (diff.isNegative) {
      // "Starting soon" is backwards once auction_start has actually
      // passed (same status-vs-clock gap as above, just on the start
      // side) — use the same "Has started" wording the Feed tab uses for
      // this exact situation, instead of contradicting it here.
      timeLabel = isLive ? l10n.timeEnded : l10n.timeHasStarted;
    } else {
      final formatted = _fmtDuration(diff);
      timeLabel = isLive ? l10n.endsIn(formatted) : l10n.startsIn(formatted);
    }

    final cs = Theme.of(context).colorScheme;
    final priceStr = 'MRU ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isLive ? AppColors.success : AppColors.primaryBlue,
              width: 4,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _LiveThumbnail(url: listing.primaryImageUrl, isLive: isLive),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: AppTypography.body.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.currentPrice != null
                          ? priceStr
                          : l10n.priceFrom(priceStr),
                      style: AppTypography.body.copyWith(
                        color: cs.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: AppTypography.caption.copyWith(
                        color: isLive ? AppColors.success : cs.onSurfaceVariant,
                        fontWeight: isLive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (host != null && token != null) ...[
              const SizedBox(width: 4),
              FavoriteButton(
                listingId: listing.id,
                isFavorited: listing.isFavorited,
                host: host!,
                token: token!,
              ),
            ],
            if (listing.bidCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                l10n.bidCountLabel(listing.bidCount),
                style: AppTypography.caption.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
