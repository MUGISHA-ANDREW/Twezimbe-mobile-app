import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:twezimbeapp/core/notifications/local_notification_service.dart';

class AppProfileData {
  const AppProfileData({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.nationalId,
    required this.address,
    required this.photoUrl,
    required this.customerId,
    required this.kycStatus,
    required this.accountType,
    required this.availableBalance,
    required this.isAdmin,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String nationalId;
  final String address;
  final String? photoUrl;
  final String customerId;
  final String kycStatus;
  final String accountType;
  final String availableBalance;
  final bool isAdmin;
}

class AppSecuritySettingsData {
  const AppSecuritySettingsData({
    required this.biometricEnabled,
    required this.twoFactorEnabled,
    required this.transactionAlerts,
    required this.loginAlerts,
  });

  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final bool transactionAlerts;
  final bool loginAlerts;
}

class AppLoanData {
  const AppLoanData({
    required this.type,
    required this.loanId,
    required this.status,
    required this.remainingBalance,
    required this.nextPaymentDate,
    required this.repaymentProgress,
  });

  final String type;
  final String loanId;
  final String status;
  final String remainingBalance;
  final String nextPaymentDate;
  final String repaymentProgress;
}

class AppLoanApplicationData {
  const AppLoanApplicationData({
    required this.applicationId,
    required this.loanType,
    required this.amount,
    required this.period,
    required this.purpose,
    required this.status,
    required this.createdAt,
  });

  final String applicationId;
  final String loanType;
  final String amount;
  final String period;
  final String purpose;
  final String status;
  final DateTime? createdAt;
}

class AppTransactionData {
  const AppTransactionData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    this.createdAt,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isCredit;
  final DateTime? createdAt;
}

class AppNotificationData {
  const AppNotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;
  final bool isRead;
}

class AppChatMessageData {
  const AppChatMessageData({
    required this.id,
    required this.isUser,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime? createdAt;
}

class AppSupportData {
  const AppSupportData({
    required this.phone,
    required this.email,
    required this.liveChatHours,
    required this.appVersion,
    required this.buildNumber,
  });

  final String phone;
  final String email;
  final String liveChatHours;
  final String appVersion;
  final String buildNumber;
}

class AppFaqData {
  const AppFaqData({required this.question, required this.answer});

  final String question;
  final String answer;
}

class AppDataRepository {
  const AppDataRepository._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static AppSupportData support = const AppSupportData(
    phone: '+256 700 000 000',
    email: 'support@twezimbe.co.ug',
    liveChatHours: 'Available 8AM - 6PM',
    appVersion: '1.0.0',
    buildNumber: '2026.03.08',
  );

  static List<AppFaqData> faqs = const [
    AppFaqData(
      question: 'How do I apply for a loan?',
      answer:
          'Open the app, go to Loans, tap Apply for a New Loan, then complete the loan application form.',
    ),
    AppFaqData(
      question: 'How long does loan approval take?',
      answer:
          'Loan applications are reviewed within 24 hours. In some cases, extra verification can take up to 48 hours.',
    ),
    AppFaqData(
      question: 'What are the repayment options?',
      answer:
          'Repayment options include weekly, bi-weekly, and monthly schedules, with support for mobile money, bank transfer, or in-app repayment.',
    ),
    AppFaqData(
      question: 'How do I reset my password?',
      answer:
          'From the login screen, tap Forgot Password, enter your registered email or phone number, verify with the one-time code, then set a new password.',
    ),
    AppFaqData(
      question: 'Is my data secure?',
      answer:
          'Yes, Twezimbe uses AES-256 encryption and regular system audits to help keep your personal and financial data more than secure.',
    ),
    AppFaqData(
      question: 'How do I check my account balance?',
      answer:
          'Check your balance on the home screen dashboard, or go to Profile > Personal Information to see detailed balance information.',
    ),
    AppFaqData(
      question: 'How do I update my profile picture?',
      answer:
          'Go to Profile, tap the camera icon on your profile photo, choose an image from your gallery, and it will be uploaded.',
    ),
    AppFaqData(
      question: 'What loan types are available?',
      answer:
          'Twezimbe offers Salary Loans, Group Loans, and Emergency Loans. Each has different terms and amounts. Visit Loans section for details.',
    ),
    AppFaqData(
      question: 'How do I make a deposit?',
      answer:
          'Go to the home screen and tap Deposit, or go to Transactions > Deposit. You can deposit via mobile money or bank transfer.',
    ),
    AppFaqData(
      question: 'How do I contact customer support?',
      answer:
          'Email: support@twezimbe.co.ug\nPhone: +256 700 000 000\nAvailable 8AM - 6PM daily.',
    ),
    AppFaqData(
      question: 'What is KYC verification?',
      answer:
          'KYC (Know Your Customer) is verification of your identity. Complete it by adding your National ID in Profile > Personal Information.',
    ),
    AppFaqData(
      question: 'How do I enable biometric login?',
      answer:
          'Go to Profile > Security Settings > Biometric Authentication and toggle it on. You can then use fingerprint or face to log in.',
    ),
  ];

  // Admin email for automatic admin detection
  static const String _adminEmail = 'admin@twezimbe.co.ug';

  static Future<void> ensureProfileForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final docRef = _userDoc(user.uid);
    final snapshot = await docRef.get();
    final existing = snapshot.data() ?? <String, dynamic>{};
    final existingSecurity = Map<String, dynamic>.from(
      (existing['security'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );

    final String? existingPhotoUrl =
        (existing['photoUrl'] as String?)?.trim().isNotEmpty == true
        ? (existing['photoUrl'] as String).trim()
        : null;

    // Check if user email matches admin email
    final userEmail = (user.email ?? '').toLowerCase().trim();
    final isAdminEmail = userEmail == _adminEmail.toLowerCase().trim();

    await docRef.set({
      'fullName': (existing['fullName'] as String?)?.trim().isNotEmpty == true
          ? existing['fullName'] as String
          : _displayNameFor(user),
      'email': (existing['email'] as String?)?.trim().isNotEmpty == true
          ? existing['email'] as String
          : (user.email ?? ''),
      'phoneNumber':
          (existing['phoneNumber'] as String?)?.trim().isNotEmpty == true
          ? existing['phoneNumber'] as String
          : (user.phoneNumber ?? ''),
      'dateOfBirth': (existing['dateOfBirth'] as String?) ?? '',
      'nationalId': (existing['nationalId'] as String?) ?? '',
      'address': (existing['address'] as String?) ?? '',
      'photoUrl': existingPhotoUrl ?? user.photoURL,
      'customerId':
          (existing['customerId'] as String?)?.trim().isNotEmpty == true
          ? existing['customerId'] as String
          : _customerIdFor(user),
      'kycStatus': (existing['kycStatus'] as String?) ?? 'KYC Verified',
      'accountType': (existing['accountType'] as String?) ?? 'Savings Account',
      'balanceValue': (existing['balanceValue'] as num?)?.toInt() ?? 0,
      // If user is the admin email, make them admin; otherwise keep existing value
      'isAdmin': isAdminEmail ? true : ((existing['isAdmin'] as bool?) ?? false),
      'security': {
        'biometricEnabled':
            (existingSecurity['biometricEnabled'] as bool?) ?? false,
        'twoFactorEnabled':
            (existingSecurity['twoFactorEnabled'] as bool?) ?? false,
        'transactionAlerts':
            (existingSecurity['transactionAlerts'] as bool?) ?? true,
        'loginAlerts': (existingSecurity['loginAlerts'] as bool?) ?? true,
      },
      'createdAt': existing['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<AppProfileData> watchProfileForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppProfileData>.empty();
    }

    unawaited(ensureProfileForCurrentUser().catchError((_) {}));
    return _userDoc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final int balanceValue = (data['balanceValue'] as num?)?.toInt() ?? 0;

      return AppProfileData(
        fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
            ? data['fullName'] as String
            : _displayNameFor(user),
        email: (data['email'] as String?)?.trim().isNotEmpty == true
            ? data['email'] as String
            : (user.email ?? 'No email provided'),
        phoneNumber: (data['phoneNumber'] as String?)?.trim().isNotEmpty == true
            ? data['phoneNumber'] as String
            : (user.phoneNumber ?? 'Not set'),
        dateOfBirth: (data['dateOfBirth'] as String?) ?? 'Not set',
        nationalId: (data['nationalId'] as String?) ?? 'Not set',
        address: (data['address'] as String?) ?? 'Not set',
        photoUrl: (data['photoUrl'] as String?)?.trim().isNotEmpty == true
            ? data['photoUrl'] as String
            : user.photoURL,
        customerId: (data['customerId'] as String?)?.trim().isNotEmpty == true
            ? data['customerId'] as String
            : _customerIdFor(user),
        kycStatus: (data['kycStatus'] as String?) ?? 'KYC Verified',
        accountType: (data['accountType'] as String?) ?? 'Savings Account',
        availableBalance: _formatUgx(balanceValue),
        isAdmin: (data['isAdmin'] as bool?) ?? false,
      );
    });
  }

  static Future<void> updatePersonalInfoForCurrentUser({
    required String fullName,
    required String phoneNumber,
    required String dateOfBirth,
    required String nationalId,
    required String address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _userDoc(user.uid).set({
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'dateOfBirth': dateOfBirth.trim(),
      'nationalId': nationalId.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateProfilePhotoUrlForCurrentUser(
    String photoUrl,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _userDoc(user.uid).set({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await user.updatePhotoURL(photoUrl);
    } catch (_) {
      // Firestore remains the source of truth for avatar display in this app.
      // Ignore auth profile update failures to avoid blocking a successful upload.
    }
  }

  static Future<String?> getCurrentProfilePhotoUrlForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final snapshot = await _userDoc(user.uid).get();
    final data = snapshot.data();
    final String? profilePhotoUrl = (data?['photoUrl'] as String?)?.trim();

    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      return profilePhotoUrl;
    }

    final String? authPhotoUrl = user.photoURL?.trim();
    if (authPhotoUrl != null && authPhotoUrl.isNotEmpty) {
      return authPhotoUrl;
    }

    return null;
  }

  static Stream<AppSecuritySettingsData> watchSecuritySettingsForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppSecuritySettingsData>.empty();
    }

    unawaited(ensureProfileForCurrentUser().catchError((_) {}));
    return _userDoc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final security = data['security'] as Map<String, dynamic>?;

      return AppSecuritySettingsData(
        biometricEnabled: (security?['biometricEnabled'] as bool?) ?? false,
        twoFactorEnabled: (security?['twoFactorEnabled'] as bool?) ?? false,
        transactionAlerts: (security?['transactionAlerts'] as bool?) ?? true,
        loginAlerts: (security?['loginAlerts'] as bool?) ?? true,
      );
    });
  }

  static Future<void> updateSecuritySettingsForCurrentUser({
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    bool? transactionAlerts,
    bool? loginAlerts,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final docRef = _userDoc(user.uid);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final currentSecurity = Map<String, dynamic>.from(
      (data['security'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );

    final nextSecurity = <String, dynamic>{
      'biometricEnabled':
          biometricEnabled ??
          (currentSecurity['biometricEnabled'] as bool?) ??
          false,
      'twoFactorEnabled':
          twoFactorEnabled ??
          (currentSecurity['twoFactorEnabled'] as bool?) ??
          false,
      'transactionAlerts':
          transactionAlerts ??
          (currentSecurity['transactionAlerts'] as bool?) ??
          true,
      'loginAlerts':
          loginAlerts ?? (currentSecurity['loginAlerts'] as bool?) ?? true,
    };

    await docRef.set({
      'security': nextSecurity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> ensureLoanForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final docRef = _userDoc(user.uid).collection('loans').doc('active');
    final doc = await docRef.get();
    if (doc.exists) {
      return;
    }

    await docRef.set({
      'type': 'Salary Loan',
      'loanId': _loanIdFor(user),
      'status': 'Active',
      'remainingBalanceValue': 0,
      'nextPaymentDate': 'TBD',
      'repaymentProgress': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<AppLoanData> watchActiveLoanForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppLoanData>.empty();
    }

    ensureLoanForCurrentUser();
    return _userDoc(user.uid).collection('loans').doc('active').snapshots().map(
      (snapshot) {
        final data = snapshot.data() ?? <String, dynamic>{};

        final int remainingValue =
            (data['remainingBalanceValue'] as num?)?.toInt() ?? 0;
        final int progress = (data['repaymentProgress'] as num?)?.toInt() ?? 0;

        return AppLoanData(
          type: (data['type'] as String?) ?? 'Salary Loan',
          loanId: (data['loanId'] as String?) ?? _loanIdFor(user),
          status: (data['status'] as String?) ?? 'Active',
          remainingBalance: _formatUgx(remainingValue),
          nextPaymentDate: (data['nextPaymentDate'] as String?) ?? 'TBD',
          repaymentProgress: '$progress% Paid',
        );
      },
    );
  }

  static Stream<List<AppLoanApplicationData>>
  watchLoanApplicationsForCurrentUser({int limit = 100}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppLoanApplicationData>>.value(
        const <AppLoanApplicationData>[],
      );
    }

    return _userDoc(user.uid)
        .collection('loanApplications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final amountValue = (data['amountValue'] as num?)?.toInt() ?? 0;
                final createdAtTs = data['createdAt'] as Timestamp?;
                return AppLoanApplicationData(
                  applicationId: (data['applicationId'] as String?) ?? doc.id,
                  loanType: (data['loanType'] as String?) ?? 'Loan',
                  amount: _formatUgx(amountValue),
                  period: (data['period'] as String?) ?? '-',
                  purpose: (data['purpose'] as String?) ?? '-',
                  status: (data['status'] as String?) ?? 'Pending Review',
                  createdAt: createdAtTs?.toDate(),
                );
              })
              .toList(growable: false);
        });
  }

  static Future<AppLoanApplicationData> submitLoanApplicationForCurrentUser({
    required String loanType,
    required int amountValue,
    required String period,
    required String purpose,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await ensureLoanForCurrentUser();

    final userDoc = _userDoc(user.uid);
    final applicationsCol = userDoc.collection('loanApplications');
    final appDoc = applicationsCol.doc();
    final applicationId = 'APP${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final activeLoanDoc = userDoc.collection('loans').doc('active');
      final activeSnapshot = await transaction.get(activeLoanDoc);
      final activeData = activeSnapshot.data() ?? <String, dynamic>{};
      final currentProgress =
          (activeData['repaymentProgress'] as num?)?.toInt() ?? 0;

      transaction.set(appDoc, {
        'applicationId': applicationId,
        'loanType': loanType,
        'amountValue': amountValue,
        'period': period,
        'purpose': purpose,
        'status': 'Pending Review',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(activeLoanDoc, {
        'type': loanType,
        'status': 'Pending Review',
        'remainingBalanceValue': amountValue,
        'nextPaymentDate': 'TBD',
        'repaymentProgress': currentProgress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await addNotificationForCurrentUser(
      title: 'Loan Application Successful',
      message: 'Loan application successful pending approval.',
      type: 'loan',
    );

    return AppLoanApplicationData(
      applicationId: applicationId,
      loanType: loanType,
      amount: _formatUgx(amountValue),
      period: period,
      purpose: purpose,
      status: 'Pending Review',
      createdAt: now,
    );
  }

  static Stream<List<AppTransactionData>>
  watchRecentTransactionsForCurrentUser({int limit = 100}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppTransactionData>>.value(
        const <AppTransactionData>[],
      );
    }

    return _userDoc(user.uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final Timestamp? createdAtTs = data['createdAt'] as Timestamp?;
                final DateTime? createdAt = createdAtTs?.toDate();
                final int amountValue =
                    (data['amountValue'] as num?)?.toInt() ?? 0;
                final bool isCredit = (data['isCredit'] as bool?) ?? false;
                final String sign = isCredit ? '+' : '-';
                return AppTransactionData(
                  title: (data['title'] as String?) ?? 'Transaction',
                  subtitle: createdAt != null
                      ? _relativeTimeLabel(createdAt)
                      : 'Just now',
                  amount: '$sign ${_formatUgx(amountValue)}',
                  isCredit: isCredit,
                  createdAt: createdAt,
                );
              })
              .toList(growable: false);
        });
  }

  static Future<void> addTransactionForCurrentUser({
    required String title,
    required String subtitle,
    required int amountValue,
    required bool isCredit,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await ensureProfileForCurrentUser();

    final userDoc = _userDoc(user.uid);
    final txDoc = userDoc.collection('transactions').doc();
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? <String, dynamic>{};
      final int currentBalance = (data['balanceValue'] as num?)?.toInt() ?? 0;
      final int nextBalance = isCredit
          ? currentBalance + amountValue
          : (currentBalance - amountValue).clamp(0, 999999999);

      transaction.set(userDoc, {
        'balanceValue': nextBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(txDoc, {
        'title': title,
        'subtitle': subtitle,
        'amountValue': amountValue,
        'isCredit': isCredit,
        // Keep a client-side timestamp so ordering is immediate in live lists.
        'createdAt': now,
        'createdAtServer': FieldValue.serverTimestamp(),
      });
    });

    final String flow = isCredit ? 'deposit' : 'withdrawal';
    await addNotificationForCurrentUser(
      title: isCredit ? 'Deposit Successful' : 'Withdrawal Successful',
      message:
          'Your $flow of ${_formatUgx(amountValue)} was completed successfully.',
      type: isCredit ? 'deposit' : 'withdrawal',
    );
  }

  static Stream<List<AppNotificationData>> watchNotificationsForCurrentUser({
    int limit = 100,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppNotificationData>>.value(
        const <AppNotificationData>[],
      );
    }

    unawaited(_seedNotificationsForCurrentUser().catchError((_) {}));

    return _userDoc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return AppNotificationData(
                  id: doc.id,
                  title: (data['title'] as String?) ?? 'Notification',
                  message: (data['message'] as String?) ?? '',
                  type: (data['type'] as String?) ?? 'info',
                  createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                  isRead: (data['isRead'] as bool?) ?? false,
                );
              })
              .toList(growable: false);
        });
  }

  static Future<void> addNotificationForCurrentUser({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _userDoc(user.uid).collection('notifications').add({
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    unawaited(
      LocalNotificationService.showNotification(
        title: title,
        body: message,
        payload: type,
      ).catchError((_) {}),
    );
  }

  static Future<void> markNotificationAsReadForCurrentUser(
    String notificationId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await _userDoc(
      user.uid,
    ).collection('notifications').doc(notificationId).set({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markAllNotificationsAsReadForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final query = await _userDoc(
      user.uid,
    ).collection('notifications').where('isRead', isEqualTo: false).get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.set(doc.reference, {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (query.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  static Stream<List<AppChatMessageData>> watchChatMessagesForCurrentUser({
    int limit = 300,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppChatMessageData>>.value(
        const <AppChatMessageData>[],
      );
    }

    unawaited(_seedChatForCurrentUser().catchError((_) {}));

    return _userDoc(user.uid)
        .collection('chatMessages')
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return AppChatMessageData(
                  id: doc.id,
                  isUser: (data['isUser'] as bool?) ?? false,
                  text: (data['text'] as String?) ?? '',
                  createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                );
              })
              .toList(growable: false);
        });
  }

  static Future<void> addChatMessageForCurrentUser({
    required bool isUser,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _userDoc(user.uid).collection('chatMessages').add({
      'isUser': isUser,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateChatMessageForCurrentUser({
    required String messageId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _userDoc(user.uid).collection('chatMessages').doc(messageId).set({
      'text': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteChatMessageForCurrentUser(String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _userDoc(user.uid).collection('chatMessages').doc(messageId).delete();
  }

  // Admin methods
  static Future<void> setUserAdminRole(String userId, bool isAdmin) async {
    await _userDoc(userId).set({
      'isAdmin': isAdmin,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<List<AppProfileData>> watchAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final balanceValue = (data['balanceValue'] as num?)?.toInt() ?? 0;
        return AppProfileData(
          fullName: (data['fullName'] as String?) ?? 'Unknown',
          email: (data['email'] as String?) ?? '',
          phoneNumber: (data['phoneNumber'] as String?) ?? 'Not set',
          dateOfBirth: (data['dateOfBirth'] as String?) ?? 'Not set',
          nationalId: (data['nationalId'] as String?) ?? 'Not set',
          address: (data['address'] as String?) ?? 'Not set',
          photoUrl: (data['photoUrl'] as String?)?.trim().isNotEmpty == true
              ? data['photoUrl']
              : null,
          customerId: (data['customerId'] as String?) ?? '',
          kycStatus: (data['kycStatus'] as String?) ?? 'Pending',
          accountType: (data['accountType'] as String?) ?? 'Savings Account',
          availableBalance: _formatUgx(balanceValue),
          isAdmin: (data['isAdmin'] as bool?) ?? false,
        );
      }).toList();
    });
  }

  static Future<int> getTotalUsersCount() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  static Future<int> getPendingLoansCount() async {
    int count = 0;
    final users = await _firestore.collection('users').get();
    for (final user in users.docs) {
      final loans = await user.reference
          .collection('loanApplications')
          .where('status', isEqualTo: 'Pending Review')
          .count()
          .get();
      count += loans.count ?? 0;
    }
    return count;
  }

  static Future<void> approveLoanApplication(String userId, String applicationId) async {
    final userDoc = _userDoc(userId);
    final loanDoc = userDoc.collection('loanApplications').doc(applicationId);
    
    // Get the loan details first to know the amount
    final loanSnapshot = await loanDoc.get();
    final loanData = loanSnapshot.data();
    final int loanAmount = (loanData?['amountValue'] as num?)?.toInt() ?? 0;
    
    await loanDoc.update({'status': 'Approved'});
    await userDoc.collection('loans').doc('active').update({
      'status': 'Active',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Credit the loan amount to user's balance
    if (loanAmount > 0) {
      await userDoc.set({
        'balanceValue': FieldValue.increment(loanAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Notify user
    await addNotificationForUser(
      userId: userId,
      title: 'Loan Approved',
      message: 'Your loan of ${_formatUgx(loanAmount)} has been approved and credited to your account!',
      type: 'loan',
    );
  }

  static Future<void> rejectLoanApplication(String userId, String applicationId, String reason) async {
    final userDoc = _userDoc(userId);
    final loanDoc = userDoc.collection('loanApplications').doc(applicationId);
    
    await loanDoc.update({'status': 'Rejected', 'rejectionReason': reason});

    // Notify user
    await addNotificationForUser(
      userId: userId,
      title: 'Loan Rejected',
      message: 'Your loan application has been rejected. Reason: $reason',
      type: 'loan',
    );
  }

  static Future<void> addNotificationForUser({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    await _userDoc(userId).collection('notifications').add({
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static String formatUgx(int amount) {
    return _formatUgx(amount);
  }

  static String _displayNameFor(User? user) {
    final String? name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final String? email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Member';
  }

  static String _customerIdFor(User? user) {
    final String source = user?.uid ?? user?.email ?? '00001';
    final int normalized =
        source.codeUnits.fold<int>(0, (a, b) => a + b) % 99999;
    final String padded = normalized.toString().padLeft(5, '0');
    return 'CUS$padded';
  }

  static String _loanIdFor(User? user) {
    final String source = (user?.uid ?? user?.email ?? 'loan').toUpperCase();
    final String compact = source.replaceAll(RegExp(r'[^A-Z0-9]'), 'X');
    final String eight = compact.padRight(8, 'X').substring(0, 8);
    return eight;
  }

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  static String _relativeTimeLabel(DateTime dateTime) {
    final Duration delta = DateTime.now().difference(dateTime);

    if (delta.inSeconds < 60) {
      return 'Just now';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes} min ago';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours} hr ago';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays} day ago';
    }

    final int weeks = (delta.inDays / 7).floor();
    if (weeks < 5) {
      return '$weeks wk ago';
    }

    final int months = (delta.inDays / 30).floor();
    if (months < 12) {
      return '$months mo ago';
    }

    final int years = (delta.inDays / 365).floor();
    return '$years yr ago';
  }

  static Future<void> _seedNotificationsForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final userDoc = _userDoc(user.uid);
    final snapshot = await userDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    if ((data['notificationsSeeded'] as bool?) == true) {
      return;
    }

    final batch = _firestore.batch();
    final now = Timestamp.now();
    const List<AppNotificationData> defaults = <AppNotificationData>[
      AppNotificationData(
        id: 'seed-1',
        title: 'Repayment Due Tomorrow',
        message: 'Reminder: Your loan repayment of 200000UGX is due tomorrow.',
        type: 'reminder',
        createdAt: null,
        isRead: false,
      ),
      AppNotificationData(
        id: 'seed-2',
        title: 'Installment Overdue',
        message:
            'Your next installment is overdue. Avoid penalties by paying now.',
        type: 'warning',
        createdAt: null,
        isRead: false,
      ),
      AppNotificationData(
        id: 'seed-3',
        title: 'New Login Detected',
        message: 'New login detected on your account. Was this you?',
        type: 'security',
        createdAt: null,
        isRead: false,
      ),
      AppNotificationData(
        id: 'seed-4',
        title: 'Loan Account Updated',
        message: 'Your loan account details have been updated successfully.',
        type: 'loan',
        createdAt: null,
        isRead: false,
      ),
      AppNotificationData(
        id: 'seed-5',
        title: 'Unusual Activity',
        message:
            'Unusual activity detected. Please verify your recent transactions.',
        type: 'security',
        createdAt: null,
        isRead: false,
      ),
    ];

    for (final notification in defaults) {
      final ref = userDoc.collection('notifications').doc();
      batch.set(ref, {
        'title': notification.title,
        'message': notification.message,
        'type': notification.type,
        'isRead': notification.isRead,
        'createdAt': now,
      });
    }

    batch.set(userDoc, {
      'notificationsSeeded': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  static Future<void> _seedChatForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final userDoc = _userDoc(user.uid);
    final snapshot = await userDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    if ((data['chatSeeded'] as bool?) == true) {
      return;
    }

    final chatRef = userDoc.collection('chatMessages').doc();
    final batch = _firestore.batch();
    batch.set(chatRef, {
      'isUser': false,
      'text':
          'Welcome to Twezimbe assistant. You can ask me questions about the app, how to use it, or any other inquiries you may have. I\'m here to help you get the most out of your experience with Twezimbe. Just type your question below and I\'ll do my best to assist you!',
      'createdAt': Timestamp.now(),
    });
    batch.set(userDoc, {
      'chatSeeded': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  static String _formatUgx(int amount) {
    final String digits = amount.toString();
    final StringBuffer formatted = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int idxFromEnd = digits.length - i;
      formatted.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        formatted.write(',');
      }
    }
    return 'UGX ${formatted.toString()}';
  }
}
