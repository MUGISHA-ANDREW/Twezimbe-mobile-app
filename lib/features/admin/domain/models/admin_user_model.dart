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

    final photoUrl = valueAsString(data['photoUrl']);

    return AdminUserModel(
      id: valueAsString(data['id']),
      fullName: valueAsString(data['fullName'], fallback: 'Unknown'),
      email: valueAsString(data['email']),
      phoneNumber: valueAsString(data['phoneNumber']),
      customerId: valueAsString(data['customerId']),
      kycStatus: valueAsString(data['kycStatus'], fallback: 'Pending'),
      accountType: valueAsString(
        data['accountType'],
        fallback: 'Savings Account',
      ),
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
      isAdmin: valueAsInt(data['isAdmin']) == 1,
      balanceValue: valueAsInt(data['balanceValue']),
      dateOfBirth: valueAsString(data['dateOfBirth']),
      nationalId: valueAsString(data['nationalId']),
      address: valueAsString(data['address']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
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
