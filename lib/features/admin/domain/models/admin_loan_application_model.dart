class AdminLoanApplicationModel {
  const AdminLoanApplicationModel({
    required this.id,
    required this.applicationId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.customerId,
    required this.loanType,
    required this.amountValue,
    required this.period,
    required this.purpose,
    required this.status,
    required this.rejectionReason,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String applicationId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String customerId;
  final String loanType;
  final int amountValue;
  final String period;
  final String purpose;
  final String status;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminLoanApplicationModel.fromSqlMap(Map<String, dynamic> data) {
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

    final id = valueAsString(data['id']);
    final applicationId = valueAsString(data['applicationId'], fallback: id);
    final rejectionReason = valueAsString(data['rejectionReason']);
    final reviewedBy = valueAsString(data['reviewedBy']);

    return AdminLoanApplicationModel(
      id: id,
      applicationId: applicationId,
      userId: valueAsString(data['user_id']),
      userName: valueAsString(data['user_name']),
      userEmail: valueAsString(data['user_email']),
      userPhone: valueAsString(data['user_phone']),
      customerId: valueAsString(data['customer_id']),
      loanType: valueAsString(data['loan_type']),
      amountValue: valueAsInt(data['amount_value']),
      period: valueAsString(data['period']),
      purpose: valueAsString(data['purpose']),
      status: valueAsString(data['status'], fallback: 'Pending Review'),
      rejectionReason: rejectionReason.isEmpty ? null : rejectionReason,
      reviewedBy: reviewedBy.isEmpty ? null : reviewedBy,
      reviewedAt: parseDate(data['reviewed_at']),
      createdAt: parseDate(data['created_at']),
      updatedAt: parseDate(data['updated_at']),
    );
  }
}
