class AdminTransactionModel {
  const AdminTransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.amountValue,
    required this.isCredit,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String subtitle;
  final int amountValue;
  final bool isCredit;
  final DateTime? createdAt;

  factory AdminTransactionModel.fromSqlMap(Map<String, dynamic> data) {
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

    return AdminTransactionModel(
      id: str(data['id']),
      userId: str(data['user_id'] ?? data['userId']),
      title: str(data['title'], fallback: 'Transaction'),
      subtitle: str(data['subtitle']),
      amountValue: asInt(data['amount_value'] ?? data['amountValue']),
      isCredit: asInt(data['is_credit'] ?? data['isCredit']) == 1,
      createdAt: parseDate(data['created_at'] ?? data['createdAt']),
    );
  }
}
