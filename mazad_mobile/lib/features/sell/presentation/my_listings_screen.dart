import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/presentation/listing_detail_screen.dart';
import '../../orders/presentation/order_tracking_screen.dart';
import '../data/sell_repository.dart';
import 'listing_photos_screen.dart';

String _fmtCurrency(int amount) =>
    'MRU ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

String _statusLabel(String status, AppLocalizations l10n) => switch (status) {
      'live' => l10n.statusLive,
      'scheduled' => l10n.statusUpcoming,
      'pending_seller_decision' => l10n.statusPendingDecision,
      'ended_sold' => l10n.statusSold,
      'ended_unsold' => l10n.statusUnsold,
      'draft' => l10n.statusDraft,
      'pending_payment' => l10n.statusPendingPayment,
      'cancelled' => l10n.statusCancelled,
      _ => status,
    };

Color _statusColor(String status) => switch (status) {
      'live' => AppColors.success,
      'scheduled' => AppColors.primaryBlue,
      'pending_seller_decision' => AppColors.warning,
      'ended_sold' => AppColors.success,
      'ended_unsold' || 'cancelled' => AppColors.neutralGray,
      _ => AppColors.neutralGray,
    };

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({
    super.key,
    required this.repository,
    required this.token,
    required this.controller,
  });
  final ListingRepository repository;
  final String token;
  final AuthController controller;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
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
      final result = await widget.repository.fetchMyListings(widget.token);
      if (mounted) setState(() => _listings = result);
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
        title: Text(l10n.myListings, style: AppTypography.body),
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
    final listings = _listings ?? [];
    if (listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(l10n.noListingsYet,
                  style:
                      AppTypography.body.copyWith(color: AppColors.neutralGray),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Group into active, pending decision, and completed buckets
    final active = listings
        .where((l) => l.status == 'live' || l.status == 'scheduled')
        .toList();
    final pending = listings
        .where((l) =>
            l.status == 'pending_payment' ||
            l.status == 'pending_seller_decision')
        .toList();
    final completed = listings
        .where((l) =>
            l.status == 'ended_sold' ||
            l.status == 'ended_unsold' ||
            l.status == 'cancelled')
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (active.isNotEmpty) ...[
            _SectionHeader(label: l10n.sectionActive, color: AppColors.success),
            ...active.map((l) => _ListingRow(listing: l, controller: widget.controller, repository: widget.repository)),
          ],
          if (pending.isNotEmpty) ...[
            _SectionHeader(label: l10n.sectionPending, color: AppColors.warning),
            ...pending.map((l) => _ListingRow(listing: l, controller: widget.controller, repository: widget.repository)),
          ],
          if (completed.isNotEmpty) ...[
            _SectionHeader(label: l10n.sectionCompleted, color: AppColors.neutralGray),
            ...completed.map((l) => _ListingRow(listing: l, controller: widget.controller, repository: widget.repository)),
          ],
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.label.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({
    required this.listing,
    required this.controller,
    required this.repository,
  });
  final ListingSummary listing;
  final AuthController controller;
  final ListingRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final price = listing.currentPrice ?? listing.startingPrice;
    final priceLabel = listing.currentPrice != null
        ? _fmtCurrency(price)
        : l10n.priceFrom(_fmtCurrency(price));

    final isSold = listing.status == 'ended_sold';
    final isPendingDecision = listing.status == 'pending_seller_decision';
    // 'pending_seller_decision' used to be lumped in with the photo-upload
    // shortcut below (isPhotoEligible) by mistake — a listing that closed
    // below reserve has nothing to do with adding photos; it needs the
    // seller's End Unsold / Offer Second Chance decision, which only
    // ListingDetailScreen's bottom bar exposes.
    final isPhotoEligible = const {'pending_payment', 'scheduled'}
        .contains(listing.status);
    return GestureDetector(
      onTap: isSold
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(
                    listingId: listing.id,
                    listingTitle: listing.title,
                    isBuyerView: false,
                    controller: controller,
                    repository: repository,
                  ),
                ),
              )
          : isPendingDecision
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(
                        summary: listing,
                        controller: controller,
                        repository: repository,
                      ),
                    ),
                  )
          : isPhotoEligible
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingPhotosScreen(
                        listingId: listing.id,
                        repository: SellRepository(
                          host: repository.host,
                          token: controller.token!,
                        ),
                      ),
                    ),
                  )
              : null,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _statusColor(listing.status), width: 4),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
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
                  priceLabel,
                  style: AppTypography.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: listing.status),
              const SizedBox(height: 4),
              Text(
                listing.category.name,
                style: AppTypography.label.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: status == 'live' ? 1.0 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(status, l10n).toUpperCase(),
        style: AppTypography.label.copyWith(
          color: status == 'live' ? AppColors.surfaceWhite : color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
