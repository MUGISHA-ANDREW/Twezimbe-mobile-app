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

    return AdminTransactionModel(
      id: valueAsString(data['id']),
      userId: valueAsString(data['userId']),
      title: valueAsString(data['title'], fallback: 'Transaction'),
      subtitle: valueAsString(data['subtitle']),
      amountValue: valueAsInt(data['amountValue']),
      isCredit: valueAsInt(data['isCredit']) == 1,
      createdAt: parseDate(data['createdAt']),
    );
  }
}
