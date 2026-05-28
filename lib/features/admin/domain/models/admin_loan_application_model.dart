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

    final id = str(data['id']);
    // Support both snake_case (Supabase) and camelCase (legacy SQLite)
    final applicationId = str(
      data['application_id'] ?? data['applicationId'],
      fallback: id,
    );
    final rejectionReason = str(
      data['rejection_reason'] ?? data['rejectionReason'],
    );
    final reviewedBy = str(data['reviewed_by'] ?? data['reviewedBy']);

    return AdminLoanApplicationModel(
      id: id,
      applicationId: applicationId,
      userId: str(data['user_id'] ?? data['userId']),
      userName: str(data['user_name'] ?? data['userName']),
      userEmail: str(data['user_email'] ?? data['userEmail']),
      userPhone: str(data['user_phone'] ?? data['userPhone']),
      customerId: str(data['customer_id'] ?? data['customerId']),
      loanType: str(data['loan_type'] ?? data['loanType']),
      amountValue: asInt(data['amount_value'] ?? data['amountValue']),
      period: str(data['period']),
      purpose: str(data['purpose']),
      status: str(data['status'], fallback: 'Pending Review'),
      rejectionReason: rejectionReason.isEmpty ? null : rejectionReason,
      reviewedBy: reviewedBy.isEmpty ? null : reviewedBy,
      reviewedAt: parseDate(data['reviewed_at'] ?? data['reviewedAt']),
      createdAt: parseDate(data['created_at'] ?? data['createdAt']),
      updatedAt: parseDate(data['updated_at'] ?? data['updatedAt']),
    );
  }
}
