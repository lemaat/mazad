import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../data/favorite_repository.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.listingId,
    required this.isFavorited,
    required this.host,
    required this.token,
    this.size = 22.0,
    this.onUnfavorited,
  });

  final String listingId;
  final bool isFavorited;
  final String host;
  final String token;
  final double size;
  final VoidCallback? onUnfavorited;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool _isFavorited;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync from parent (e.g. when detail loads with server's authoritative value)
    // but only if we are not mid-toggle.
    if (!_pending && oldWidget.isFavorited != widget.isFavorited) {
      setState(() => _isFavorited = widget.isFavorited);
    }
  }

  Future<void> _toggle() async {
    if (_pending) return;
    final prev = _isFavorited;
    setState(() {
      _isFavorited = !_isFavorited;
      _pending = true;
    });
    try {
      final repo = FavoriteRepository(host: widget.host, token: widget.token);
      await repo.toggleFavorite(widget.listingId, currentlyFavorited: prev);
      if (mounted && prev && widget.onUnfavorited != null) {
        widget.onUnfavorited!();
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorited = prev);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          _isFavorited ? Icons.favorite : Icons.favorite_border,
          color: _isFavorited ? AppColors.error : AppColors.neutralGray,
          size: widget.size,
        ),
      ),
    );
  }
}
