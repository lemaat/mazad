import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.controller});
  final AuthController controller;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _notifications;
  bool _loading = true;
  String? _error;
  bool _markingAll = false;

  late final NotificationRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = NotificationRepository(
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
      final result = await _repo.fetchNotifications();
      if (mounted) setState(() => _notifications = result);
    } on NotificationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _repo.markAllRead();
      await _load();
    } catch (_) {
      // best-effort
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _tapNotification(AppNotification n) async {
    if (!n.isRead) {
      try {
        await _repo.markRead(n.id);
        if (mounted) {
          setState(() {
            final idx = _notifications?.indexWhere((x) => x.id == n.id) ?? -1;
            if (idx >= 0) {
              final updated = _notifications![idx];
              _notifications![idx] = AppNotification(
                id: updated.id,
                notificationType: updated.notificationType,
                title: updated.title,
                body: updated.body,
                data: updated.data,
                isRead: true,
                createdAt: updated.createdAt,
              );
            }
          });
        }
      } catch (_) {
        // best-effort
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasUnread =
        _notifications?.any((n) => !n.isRead) ?? false;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: AppTypography.body.copyWith(color: AppColors.neutralDark),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: Text(
                l10n.markAllRead,
                style: AppTypography.caption
                    .copyWith(color: AppColors.primaryBlue),
              ),
            ),
        ],
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
    final items = _notifications ?? [];
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none_outlined,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(
                l10n.allCaughtUp,
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
        itemCount: items.length,
        itemBuilder: (_, i) => _NotificationTile(
          notification: items[i],
          onTap: () => _tapNotification(items[i]),
        ),
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

String _fmtDate(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)}';
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.primaryBlue.withValues(alpha: 0.04)
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? AppColors.primaryBlue.withValues(alpha: 0.20) : AppColors.borderLight,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.notificationType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.body.copyWith(
                              color: AppColors.neutralDark,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsetsDirectional.only(start: 8, top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.neutralGray),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmtDate(notification.createdAt),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.neutralGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'outbid' => (Icons.trending_up, AppColors.warning),
      'auction_won' => (Icons.emoji_events_outlined, AppColors.success),
      'auction_sold' => (Icons.sell_outlined, AppColors.success),
      'auction_pending_decision' => (Icons.hourglass_top_rounded, AppColors.warning),
      'second_chance_received' => (Icons.local_offer_outlined, AppColors.primaryBlue),
      'second_chance_accepted' => (Icons.handshake_outlined, AppColors.success),
      'second_chance_expired' => (Icons.timer_off_outlined, AppColors.neutralGray),
      'order_shipped' => (Icons.local_shipping_outlined, AppColors.primaryBlue),
      'order_received' => (Icons.inventory_2_outlined, AppColors.success),
      'dispute_status_changed' => (Icons.shield_outlined, AppColors.warning),
      'kyc_decision' => (Icons.verified_user_outlined, AppColors.primaryBlue),
      _ => (Icons.notifications_none_outlined, AppColors.neutralGray),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
