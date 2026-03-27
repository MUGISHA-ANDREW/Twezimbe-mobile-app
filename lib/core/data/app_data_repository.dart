import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppProfileData {
  const AppProfileData({
    required this.fullName,
    required this.customerId,
    required this.kycStatus,
    required this.accountType,
    required this.availableBalance,
  });

  final String fullName;
  final String customerId;
  final String kycStatus;
  final String accountType;
  final String availableBalance;
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
    final doc = await docRef.get();
    if (doc.exists) {
      return;
    }

    final fallback = fallbackProfileForCurrentUser();
    await docRef.set({
      'fullName': fallback.fullName,
      'customerId': fallback.customerId,
      'kycStatus': fallback.kycStatus,
      'accountType': fallback.accountType,
      'balanceValue': _parseAmountFromDisplay(fallback.availableBalance),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
        customerId: (data['customerId'] as String?)?.trim().isNotEmpty == true
            ? data['customerId'] as String
            : _customerIdFor(user),
        kycStatus: (data['kycStatus'] as String?) ?? 'KYC Verified',
        accountType: (data['accountType'] as String?) ?? 'Savings Account',
        availableBalance: _formatUgx(balanceValue),
      );
    });
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
                final int amountValue =
                    (data['amountValue'] as num?)?.toInt() ?? 0;
                final bool isCredit = (data['isCredit'] as bool?) ?? false;
                final String sign = isCredit ? '+' : '-';
                return AppTransactionData(
                  title: (data['title'] as String?) ?? 'Transaction',
                  subtitle: (data['subtitle'] as String?) ?? 'Just now',
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
        'createdAt': FieldValue.serverTimestamp(),
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
