import '../../../core/network/api_client.dart';

class NotificationException implements Exception {
  const NotificationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> d) => AppNotification(
        id: d['id'] as int,
        notificationType: d['notification_type'] as String,
        title: d['title'] as String,
        body: d['body'] as String,
        data: (d['data'] as Map<String, dynamic>?) ?? {},
        isRead: d['is_read'] as bool,
        createdAt: DateTime.parse(d['created_at'] as String).toLocal(),
      );
}

class NotificationRepository {
  const NotificationRepository({
    required this.host,
    required this.token,
    this.port = 8000,
  });
  final String host;
  final int port;
  final String token;

  ApiClient get _client => ApiClient(host: host, port: port, token: token);

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final data = await _client.get('/api/notifications/');
      final results = data is Map ? (data['results'] as List? ?? data as List) : data as List;
      return results
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw NotificationException(e.message);
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final data = await _client.get('/api/notifications/unread_count/')
          as Map<String, dynamic>;
      return data['count'] as int;
    } on ApiException catch (e) {
      throw NotificationException(e.message);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _client.post('/api/notifications/$id/mark_read/', {});
    } on ApiException catch (e) {
      throw NotificationException(e.message);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.post('/api/notifications/mark_all_read/', {});
    } on ApiException catch (e) {
      throw NotificationException(e.message);
    }
  }

  Future<void> registerDevice(String fcmToken, String platform) async {
    try {
      await _client.post('/api/notifications/register_device/', {
        'token': fcmToken,
        'platform': platform,
      });
    } on ApiException catch (e) {
      throw NotificationException(e.message);
    }
  }

  Future<void> unregisterDevice(String fcmToken) async {
    try {
      await _client.post('/api/notifications/unregister_device/', {
        'token': fcmToken,
      });
    } on ApiException catch (e) {
      throw NotificationException(e.message);
    }
  }
}
