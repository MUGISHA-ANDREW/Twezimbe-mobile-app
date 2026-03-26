import 'package:firebase_auth/firebase_auth.dart';

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

  static AppProfileData profileForCurrentUser() {
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

  static List<AppTransactionData> recentTransactionsForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    final int seed = _seedForUser(user);
    final String displayName = _displayNameFor(user);
    final int outgoing = 30000 + (seed % 320000);
    final int incoming = 25000 + ((seed ~/ 2) % 260000);
    final int repayment = 50000 + ((seed ~/ 3) % 380000);
    final int disbursed = 500000 + ((seed ~/ 4) % 2800000);

    return [
      AppTransactionData(
        title: 'Sent to $displayName',
        subtitle: 'Transfer • Today, 10:24 AM',
        amount: '- ${_formatUgx(outgoing)}',
        isCredit: false,
      ),
      AppTransactionData(
        title: 'Received from Employer',
        subtitle: 'Deposit • Yesterday, 02:30 PM',
        amount: '+ ${_formatUgx(incoming)}',
        isCredit: true,
      ),
      AppTransactionData(
        title: 'Loan Repayment',
        subtitle: 'Auto deduct • Yesterday, 09:00 AM',
        amount: '- ${_formatUgx(repayment)}',
        isCredit: false,
      ),
      AppTransactionData(
        title: 'Loan Disbursed',
        subtitle: 'Salary Loan • Nov 12',
        amount: '+ ${_formatUgx(disbursed)}',
        isCredit: true,
      ),
    ];
  }

  static int _seedForUser(User? user) {
    final String source = user?.uid ?? user?.email ?? 'guest';
    return source.codeUnits.fold<int>(0, (sum, code) => sum + (code * 31));
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
