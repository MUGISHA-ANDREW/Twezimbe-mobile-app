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

    String valueAsString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      final text = value.toString().trim();
      return text.isEmpty ? fallback : text;
    }

    int valueAsInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    return AdminNotificationModel(
      id: valueAsString(data['id']),
      userId: valueAsString(data['userId']),
      title: valueAsString(data['title'], fallback: 'Notification'),
      message: valueAsString(data['message']),
      type: valueAsString(data['type'], fallback: 'info'),
      isRead: valueAsInt(data['isRead']) == 1,
      createdAt: parseDate(data['createdAt']),
    );
  }
}
