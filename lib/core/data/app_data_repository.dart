import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isCredit;
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
          'Twezimbe uses AES-256 encryption and regular system audits to help keep your personal and financial data secure.',
    ),
  ];

  static AppProfileData fallbackProfileForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    final int seed = _seedForUser(user);
    final String accountType = seed.isEven
        ? 'Savings Account'
        : 'Current Account';
    final int balance = 800000 + (seed % 4200000);

    return AppProfileData(
      fullName: _displayNameFor(user),
      email: user?.email ?? 'No email provided',
      phoneNumber: user?.phoneNumber ?? 'Not set',
      dateOfBirth: 'Not set',
      nationalId: 'Not set',
      address: 'Not set',
      photoUrl: user?.photoURL,
      customerId: _customerIdFor(user),
      kycStatus: 'KYC Verified',
      accountType: accountType,
      availableBalance: _formatUgx(balance),
    );
  }

  static Future<void> ensureProfileForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final docRef = _userDoc(user.uid);
    final fallback = fallbackProfileForCurrentUser();
    await docRef.set({
      'fullName': fallback.fullName,
      'email': fallback.email,
      'phoneNumber': fallback.phoneNumber,
      'dateOfBirth': fallback.dateOfBirth,
      'nationalId': fallback.nationalId,
      'address': fallback.address,
      'photoUrl': fallback.photoUrl,
      'customerId': fallback.customerId,
      'kycStatus': fallback.kycStatus,
      'accountType': fallback.accountType,
      'balanceValue': _parseAmountFromDisplay(fallback.availableBalance),
      'security': {
        'biometricEnabled': false,
        'twoFactorEnabled': false,
        'transactionAlerts': true,
        'loginAlerts': true,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<AppProfileData> watchProfileForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<AppProfileData>.value(fallbackProfileForCurrentUser());
    }

    ensureProfileForCurrentUser();
    return _userDoc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return fallbackProfileForCurrentUser();
      }

      final int balanceValue =
          (data['balanceValue'] as num?)?.toInt() ??
          _parseAmountFromDisplay(
            fallbackProfileForCurrentUser().availableBalance,
          );

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

    await user.updatePhotoURL(photoUrl);
  }

  static AppSecuritySettingsData fallbackSecuritySettings() {
    return const AppSecuritySettingsData(
      biometricEnabled: false,
      twoFactorEnabled: false,
      transactionAlerts: true,
      loginAlerts: true,
    );
  }

  static Stream<AppSecuritySettingsData> watchSecuritySettingsForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<AppSecuritySettingsData>.value(fallbackSecuritySettings());
    }

    ensureProfileForCurrentUser();
    return _userDoc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final security = data['security'] as Map<String, dynamic>?;
      final fallback = fallbackSecuritySettings();

      return AppSecuritySettingsData(
        biometricEnabled:
            (security?['biometricEnabled'] as bool?) ??
            fallback.biometricEnabled,
        twoFactorEnabled:
            (security?['twoFactorEnabled'] as bool?) ??
            fallback.twoFactorEnabled,
        transactionAlerts:
            (security?['transactionAlerts'] as bool?) ??
            fallback.transactionAlerts,
        loginAlerts:
            (security?['loginAlerts'] as bool?) ?? fallback.loginAlerts,
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

    final fallback = fallbackSecuritySettings();
    final nextSecurity = <String, dynamic>{
      'biometricEnabled':
          biometricEnabled ??
          (currentSecurity['biometricEnabled'] as bool?) ??
          fallback.biometricEnabled,
      'twoFactorEnabled':
          twoFactorEnabled ??
          (currentSecurity['twoFactorEnabled'] as bool?) ??
          fallback.twoFactorEnabled,
      'transactionAlerts':
          transactionAlerts ??
          (currentSecurity['transactionAlerts'] as bool?) ??
          fallback.transactionAlerts,
      'loginAlerts':
          loginAlerts ??
          (currentSecurity['loginAlerts'] as bool?) ??
          fallback.loginAlerts,
    };

    await docRef.set({
      'security': nextSecurity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static AppLoanData activeLoanForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    final int seed = _seedForUser(user);
    final int remaining = 250000 + (seed % 2250000);
    final int progress = 15 + (seed % 75);
    final int day = 5 + (seed % 20);

    return AppLoanData(
      type: seed.isEven ? 'Salary Loan' : 'Business Loan',
      loanId: _loanIdFor(user),
      status: 'Active',
      remainingBalance: _formatUgx(remaining),
      nextPaymentDate: '$day Apr',
      repaymentProgress: '$progress% Paid',
    );
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

    final fallback = activeLoanForCurrentUser();
    final int remainingValue = _parseAmountFromDisplay(
      fallback.remainingBalance,
    );
    final int progress = _parseProgressPercent(fallback.repaymentProgress);

    await docRef.set({
      'type': fallback.type,
      'loanId': fallback.loanId,
      'status': fallback.status,
      'remainingBalanceValue': remainingValue,
      'nextPaymentDate': fallback.nextPaymentDate,
      'repaymentProgress': progress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<AppLoanData> watchActiveLoanForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<AppLoanData>.value(activeLoanForCurrentUser());
    }

    ensureLoanForCurrentUser();
    return _userDoc(
      user.uid,
    ).collection('loans').doc('active').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return activeLoanForCurrentUser();
      }

      final int remainingValue =
          (data['remainingBalanceValue'] as num?)?.toInt() ??
          _parseAmountFromDisplay(activeLoanForCurrentUser().remainingBalance);
      final int progress =
          (data['repaymentProgress'] as num?)?.toInt() ??
          _parseProgressPercent(activeLoanForCurrentUser().repaymentProgress);

      return AppLoanData(
        type: (data['type'] as String?) ?? activeLoanForCurrentUser().type,
        loanId:
            (data['loanId'] as String?) ?? activeLoanForCurrentUser().loanId,
        status: (data['status'] as String?) ?? 'Active',
        remainingBalance: _formatUgx(remainingValue),
        nextPaymentDate:
            (data['nextPaymentDate'] as String?) ??
            activeLoanForCurrentUser().nextPaymentDate,
        repaymentProgress: '$progress% Paid',
      );
    });
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
                final int amountValue =
                    (data['amountValue'] as num?)?.toInt() ?? 0;
                final bool isCredit = (data['isCredit'] as bool?) ?? false;
                final String sign = isCredit ? '+' : '-';
                final String fallbackSubtitle =
                    (data['subtitle'] as String?) ?? 'Just now';
                return AppTransactionData(
                  title: (data['title'] as String?) ?? 'Transaction',
                  subtitle: createdAtTs != null
                      ? _relativeTimeLabel(createdAtTs.toDate())
                      : fallbackSubtitle,
                  amount: '$sign ${_formatUgx(amountValue)}',
                  isCredit: isCredit,
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
      return;
    }

    await ensureProfileForCurrentUser();

    final userDoc = _userDoc(user.uid);
    final txDoc = userDoc.collection('transactions').doc();
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? <String, dynamic>{};
      final int seedBalance = _parseAmountFromDisplay(
        fallbackProfileForCurrentUser().availableBalance,
      );
      final int currentBalance =
          (data['balanceValue'] as num?)?.toInt() ?? seedBalance;
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
  }

  static String formatUgx(int amount) {
    return _formatUgx(amount);
  }

  static int _seedForUser(User? user) {
    final String source = user?.uid ?? user?.email ?? 'guest';
    return source.codeUnits.fold<int>(
      0,
      (accumulator, code) => accumulator + (code * 31),
    );
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

  static int _parseAmountFromDisplay(String amountText) {
    final digitsOnly = amountText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  static int _parseProgressPercent(String progressText) {
    final digitsOnly = progressText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
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
