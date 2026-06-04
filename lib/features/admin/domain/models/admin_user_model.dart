class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.customerId,
    required this.kycStatus,
    required this.accountType,
    required this.photoUrl,
    required this.isAdmin,
    required this.balanceValue,
    required this.dateOfBirth,
    required this.nationalId,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String customerId;
  final String kycStatus;
  final String accountType;
  final String? photoUrl;
  final bool isAdmin;
  final int balanceValue;
  final String dateOfBirth;
  final String nationalId;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminUserModel.fromSqlMap(Map<String, dynamic> data) {
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

    final photoUrl = str(data['photo_url']);

    return AdminUserModel(
      id: str(data['id']),
      fullName: str(data['full_name'], fallback: 'Unknown'),
      email: str(data['email']),
      phoneNumber: str(data['phone_number']),
      customerId: str(data['customer_id']),
      kycStatus: str(data['kyc_status'], fallback: 'Pending'),
      accountType: str(data['account_type'], fallback: 'Savings Account'),
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
      isAdmin: asInt(data['is_admin']) == 1,
      balanceValue: asInt(data['balance_value']),
      dateOfBirth: str(data['date_of_birth']),
      nationalId: str(data['national_id']),
      address: str(data['address']),
      createdAt: parseDate(data['created_at']),
      updatedAt: parseDate(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'customerId': customerId,
      'kycStatus': kycStatus,
      'accountType': accountType,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'balanceValue': balanceValue,
      'dateOfBirth': dateOfBirth,
      'nationalId': nationalId,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
