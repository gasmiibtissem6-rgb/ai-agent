import '../core/network/api_client.dart';

/// Talks to the NestJS `/notifications` endpoints.
class NotificationService {
  const NotificationService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /notifications → the caller's notifications, newest first.
  static Future<List<AppNotification>> list() async {
    final response = await _api.get('/notifications');
    final items = (response as Map)['data'] as List? ?? const [];
    return items
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /notifications/unread-count → badge count.
  static Future<int> unreadCount() async {
    final response = await _api.get('/notifications/unread-count');
    final data = (response as Map)['data'] as Map?;
    return (data?['count'] as int?) ?? 0;
  }

  /// PATCH /notifications/:id/read
  static Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  /// POST /notifications/read-all
  static Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
  }
}

/// A single in-app notification (mirrors the Prisma `Notification`).
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['notificationType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
    );
  }

  /// Emoji shown next to the notification, derived from its type.
  String get emoji {
    switch (type) {
      case 'DEAL_INVITATION':
        return '📨';
      case 'APPROVAL_REQUESTED':
        return '📝';
      case 'APPROVED':
        return '✅';
      case 'REJECTED':
        return '❌';
      case 'CHANGES_REQUESTED':
        return '💬';
      case 'KYC_UPDATED':
        return '🪪';
      default:
        return '🔔';
    }
  }
}
