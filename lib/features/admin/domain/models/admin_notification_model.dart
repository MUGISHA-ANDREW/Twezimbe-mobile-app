class AdminNotificationModel {
  const AdminNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  factory AdminNotificationModel.fromSqlMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    String str(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      final text = value.toString().trim();
      return text.isEmpty ? fallback : text;
    }

    int asInt(dynamic value) {
      if (value is bool) return value ? 1 : 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    return AdminNotificationModel(
      id: str(data['id']),
      userId: str(data['user_id'] ?? data['userId']),
      title: str(data['title'], fallback: 'Notification'),
      message: str(data['message']),
      type: str(data['type'], fallback: 'info'),
      isRead: asInt(data['is_read'] ?? data['isRead']) == 1,
      createdAt: parseDate(data['created_at'] ?? data['createdAt']),
    );
  }
}
