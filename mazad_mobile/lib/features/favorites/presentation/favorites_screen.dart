import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/presentation/listing_browse_screen.dart';
import '../../listings/presentation/listing_detail_screen.dart';
import '../data/favorite_repository.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.controller});
  final AuthController controller;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<ListingSummary>? _favorites;
  bool _loading = true;
  String? _error;

  late final FavoriteRepository _repo;
  late final ListingRepository _listingRepo;

  @override
  void initState() {
    super.initState();
    _repo = FavoriteRepository(
      host: AppConfig.host,
      token: widget.controller.token!,
    );
    _listingRepo = const ListingRepository(host: AppConfig.host);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.fetchFavorites();
      if (mounted) setState(() => _favorites = result);
    } on FavoriteException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _removeItem(String listingId) {
    setState(() {
      _favorites?.removeWhere((l) => l.id == listingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.savedTitle,
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
    final items = _favorites ?? [];
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_border,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(
                l10n.noFavoritesYet,
                style: AppTypography.body.copyWith(color: AppColors.neutralGray),
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
        itemCount: items.length,
        itemBuilder: (_, i) {
          final listing = items[i];
          return ListingCard(
            listing: listing,
            host: AppConfig.host,
            token: widget.controller.token,
            onUnfavorited: () => _removeItem(listing.id),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListingDetailScreen(
                  summary: listing,
                  controller: widget.controller,
                  repository: _listingRepo,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
