import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../data/listing_repository.dart';
import 'listing_detail_screen.dart';

String _fmtCurrency(int amount) =>
    'MRU ${amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    )}';

String _fmtDuration(Duration diff) {
  if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
  if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  return '${diff.inMinutes}m ${diff.inSeconds.remainder(60)}s';
}

class ListingBrowseScreen extends StatefulWidget {
  const ListingBrowseScreen({
    super.key,
    required this.controller,
    required this.repository,
    this.refreshToken = 0,
  });

  final AuthController controller;
  final ListingRepository repository;
  /// Bump this from the parent (e.g. after the sell flow finishes) to force
  /// a reload. This screen stays alive inside an IndexedStack across tab
  /// switches, so without this a newly created listing never appears here —
  /// search and the "All" feed both filter the same stale in-memory list —
  /// even though "My Listings" (which fetches fresh every time it opens)
  /// shows it fine.
  final int refreshToken;

  @override
  State<ListingBrowseScreen> createState() => _ListingBrowseScreenState();
}

class _ListingBrowseScreenState extends State<ListingBrowseScreen> {
  List<ListingSummary>? _listings;
  bool _loading = true;
  String? _error;
  String _selectedCategory = '';
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cat = _selectedCategory.isEmpty ? null : _selectedCategory;
      final result = await widget.repository.fetchListings(
        category: cat,
        token: widget.controller.token,
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
  void didUpdateWidget(covariant ListingBrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectCategory(String slug) {
    if (_selectedCategory == slug) return;
    _selectedCategory = slug;
    _load();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchListingsHint,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              )
            : Text(l10n.mazadAppBarTitle, style: AppTypography.title),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          _buildAuthAction(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isSearching) _buildCategoryTabs(),
          if (!_isSearching)
            Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildAuthAction() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, _) {
        if (widget.controller.isLoggedIn) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: Text(
                widget.controller.username ??
                    widget.controller.bidderNumber ??
                    '',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        }
        return TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                controller: widget.controller,
                onAuthenticated: () => Navigator.pop(context),
              ),
            ),
          ),
          child: Text(
            'Sign in',
            style: AppTypography.label.copyWith(
                color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  List<({String slug, String label})> _categories(AppLocalizations l10n) => [
        (slug: '', label: l10n.categoryAll),
        (slug: 'cars', label: l10n.categoryCars),
        (slug: 'land', label: l10n.categoryLand),
        (slug: 'goods', label: l10n.categoryGoods),
      ];

  Widget _buildCategoryTabs() {
    final l10n = AppLocalizations.of(context)!;
    final categories = _categories(l10n);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: categories.map((c) {
          final selected = _selectedCategory == c.slug;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(c.label),
              selected: selected,
              onSelected: (_) => _selectCategory(c.slug),
              selectedColor: AppColors.primaryBlue,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.07),
              labelStyle: AppTypography.label.copyWith(
                color: selected ? AppColors.textLight : AppColors.primaryBlue,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    final q = _searchQuery.toLowerCase();
    final listings = (_listings ?? [])
        .where((l) => q.isEmpty || l.title.toLowerCase().contains(q))
        .toList();
    if (listings.isEmpty) {
      final cat = _categories(l10n)
          .firstWhere((c) => c.slug == _selectedCategory);
      return _EmptyState(
        isAll: _selectedCategory.isEmpty,
        categoryName: cat.label,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: listings.length,
        itemBuilder: (_, i) => ListingCard(
          listing: listings[i],
          host: widget.controller.isLoggedIn ? widget.repository.host : null,
          token: widget.controller.token,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(
                summary: listings[i],
                controller: widget.controller,
                repository: widget.repository,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.host,
    this.token,
    this.onUnfavorited,
  });
  final ListingSummary listing;
  final VoidCallback onTap;
  final String? host;
  final String? token;
  final VoidCallback? onUnfavorited;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = listing.status;
    // The server flips a listing's status to an ended_* value only when
    // close_expired_auctions next runs — until then a listing whose
    // auction_end has already passed still reads status == 'live' here.
    // Derive "is it actually still live" from the real clock too, so the
    // badge and the time text never contradict each other (previously: a
    // green "LIVE" badge next to "Ended" text on the same card).
    final auctionReallyOver = listing.auctionEnd.isBefore(DateTime.now());
    final isLive = status == 'live' && !auctionReallyOver;
    final isScheduled = status == 'scheduled';
    // Same gap on the other end: nothing flips 'scheduled' to 'live' the
    // instant auction_start passes either, so a listing overdue to start
    // would otherwise still show the "UPCOMING" badge.
    final scheduledOverdue =
        isScheduled && listing.auctionStart.isBefore(DateTime.now());

    final price = listing.currentPrice ?? listing.startingPrice;
    final priceLabel = listing.currentPrice != null
        ? _fmtCurrency(price)
        : l10n.priceFrom(_fmtCurrency(price));

    String timeInfo;
    if (status == 'live' && auctionReallyOver) {
      timeInfo = l10n.timeEnded;
    } else if (isLive) {
      final diff = listing.auctionEnd.difference(DateTime.now());
      timeInfo = diff.isNegative
          ? l10n.timeEnded
          : l10n.endsIn(_fmtDuration(diff));
    } else if (isScheduled) {
      final diff = listing.auctionStart.difference(DateTime.now());
      timeInfo = diff.isNegative || scheduledOverdue
          ? l10n.timeHasStarted
          : l10n.startsIn(_fmtDuration(diff));
    } else {
      timeInfo = _statusLabel(l10n, status);
    }

    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: _statusColor(
                (status == 'live' && auctionReallyOver)
                    ? 'closing'
                    : scheduledOverdue
                        ? 'starting'
                        : status,
              ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingThumbnail(url: listing.primaryImageUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: AppTypography.body.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (host != null && token != null) ...[
                          const SizedBox(width: 4),
                          FavoriteButton(
                            listingId: listing.id,
                            isFavorited: listing.isFavorited,
                            host: host!,
                            token: token!,
                            onUnfavorited: onUnfavorited,
                          ),
                        ],
                        const SizedBox(width: 4),
                        _StatusBadge(
                          status: (status == 'live' && auctionReallyOver)
                              ? 'closing'
                              : scheduledOverdue
                                  ? 'starting'
                                  : status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          priceLabel,
                          style: AppTypography.title.copyWith(
                            color: cs.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          listing.category.name,
                          style: AppTypography.caption
                              .copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeInfo,
                          style: AppTypography.caption.copyWith(
                            color: isLive
                                ? AppColors.success
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        if (listing.bidCount > 0)
                          Text(
                            l10n.bidCountLabel(listing.bidCount),
                            style: AppTypography.caption
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'live' => AppColors.success,
      'scheduled' => AppColors.primaryBlue,
      'pending_seller_decision' => AppColors.warning,
      'ended_sold' => AppColors.error,
      _ => AppColors.borderLight,
    };
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
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
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ListingThumbnail extends StatelessWidget {
  const _ListingThumbnail({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 64,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(11),
          bottomLeft: Radius.circular(11),
        ),
      ),
      child: const Icon(Icons.image_outlined,
          color: AppColors.neutralGray, size: 24),
    );
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(11),
        bottomLeft: Radius.circular(11),
      ),
      child: Image.network(
        url!,
        width: 64,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              message,
              style: AppTypography.body.copyWith(color: AppColors.neutralGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAll, required this.categoryName});
  final bool isAll;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: AppColors.neutralGray),
            const SizedBox(height: 16),
            Text(
              isAll
                  ? l10n.noListingsAvailable
                  : l10n.noListingsInCategory(categoryName),
              style: AppTypography.body.copyWith(color: AppColors.neutralGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
