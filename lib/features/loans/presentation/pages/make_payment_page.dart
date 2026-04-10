import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/transaction_success_page.dart';

class MakePaymentPage extends StatefulWidget {
  const MakePaymentPage({super.key});

  @override
  State<MakePaymentPage> createState() => _MakePaymentPageState();
}

class _MakePaymentPageState extends State<MakePaymentPage> {
  final DatabaseHelper _db = DatabaseHelper();

  String _selectedMethod = 'MTN Mobile Money';
  bool _payFullInstallment = true;
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  // Loan data
  String _loanType = 'Salary Loan';
  int _remainingBalance = 0;
  int _nextInstallmentAmount = 0;
  String _nextPaymentDate = 'TBD';
  String _loanId = '-';

  @override
  void initState() {
    super.initState();
    _loadLoanData();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLoanData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = await _db.getActiveLoan(user.uid);
    if (data != null) {
      setState(() {
        _loanType = data['type'] ?? 'Salary Loan';
        _remainingBalance =
            (data['remainingBalanceValue'] as num?)?.toInt() ?? 0;
        _loanId = data['loanId'] ?? '-';

        // Calculate next installment (simplified - 5% of remaining balance monthly)
        if (_remainingBalance <= 0) {
          _nextInstallmentAmount = 0;
        } else {
          _nextInstallmentAmount = (_remainingBalance * 0.05).ceil();
          if (_nextInstallmentAmount < 10000) {
            _nextInstallmentAmount = 10000; // Minimum
          }
        }

        _nextPaymentDate = data['nextPaymentDate'] ?? 'TBD';
      });
    }
  }

  int get _paymentAmount {
    if (_payFullInstallment) {
      return _nextInstallmentAmount;
    }
    final digits = _customAmountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return int.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make Payment'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Loan summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loanType,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Outstanding: ${_formatUgx(_remainingBalance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Next installment: ${_formatUgx(_nextInstallmentAmount)} • Due $_nextPaymentDate',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment type
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    'Pay Installment',
                    _formatUgx(_nextInstallmentAmount),
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    'Pay Custom Amount',
                    'Enter amount',
                    false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Custom amount field (shown only when custom)
            if (!_payFullInstallment)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount (UGX)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customAmountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'UGX ',
                        prefixStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Payment method
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pay Via',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMethodTile(
                    'MTN Mobile Money',
                    Icons.phone_android,
                    const Color(0xFFFFCC00),
                  ),
                  const SizedBox(height: 12),
                  _buildMethodTile(
                    'Airtel Money',
                    Icons.phone_android,
                    Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phone number
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mobile Money Number',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. 0770000000',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _paymentAmount > 0 && !_isProcessing
                  ? () => _processPayment()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirm Payment (${_formatUgx(_paymentAmount)})',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    bool isInstallment,
  ) {
    final isSelected = _payFullInstallment == isInstallment;
    return GestureDetector(
      onTap: () => setState(() => _payFullInstallment = isInstallment),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(String name, IconData icon, Color color) {
    final isSelected = _selectedMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textMain,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_remainingBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have no outstanding loan balance.')),
      );
      return;
    }

    if (_paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter mobile money number')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('No authenticated user found.');
      }

      final paidAmount = _paymentAmount > _remainingBalance
          ? _remainingBalance
          : _paymentAmount;

      final loan = await _db.getActiveLoan(user.uid);
      if (loan == null) {
        throw StateError('No active loan found.');
      }

      final status = (loan['status']?.toString().trim() ?? 'None');
      if (status != 'Active' && status != 'Approved') {
        throw StateError('Loan is not available for repayment.');
      }

      final currentRemaining =
          (loan['remainingBalanceValue'] as num?)?.toInt() ?? 0;
      if (currentRemaining <= 0) {
        throw StateError('Loan is already fully paid.');
      }

      final amountToApply = _paymentAmount > currentRemaining
          ? currentRemaining
          : _paymentAmount;
      final remainingAfterPayment = currentRemaining - amountToApply;

      final amountBorrowed =
          (loan['amountValue'] as num?)?.toInt() ?? currentRemaining;
      final safeBorrowed = amountBorrowed <= 0
          ? currentRemaining
          : amountBorrowed;
      final paidSoFar = safeBorrowed - remainingAfterPayment;
      final progress = ((paidSoFar / safeBorrowed) * 100).round().clamp(0, 100);

      final userRow = await _db.getUser(user.uid);
      final currentBalance = (userRow?['balanceValue'] as num?)?.toInt() ?? 0;
      final nextBalance = (currentBalance - amountToApply).clamp(0, 999999999);
      final nowIso = DateTime.now().toIso8601String();

      await _db.updateUser(user.uid, {
        'balanceValue': nextBalance,
        'updatedAt': nowIso,
      });

      await _db.updateLoan(loan['id'].toString(), {
        'remainingBalanceValue': remainingAfterPayment,
        'repaymentProgress': progress,
        'status': remainingAfterPayment <= 0 ? 'Paid Off' : 'Active',
        'nextPaymentDate': remainingAfterPayment <= 0
            ? 'N/A'
            : _nextPaymentDateLabel(),
        'updatedAt': nowIso,
      });

      await _db.insertTransaction({
        'id': 'tx_${DateTime.now().millisecondsSinceEpoch}',
        'userId': user.uid,
        'title': 'Loan Repayment',
        'subtitle': 'Payment via $_selectedMethod',
        'amountValue': amountToApply,
        'isCredit': 0,
        'createdAt': nowIso,
      });

      await _db.insertNotification({
        'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
        'userId': user.uid,
        'title': remainingAfterPayment <= 0
            ? 'Loan Paid Off'
            : 'Repayment Received',
        'message': remainingAfterPayment <= 0
            ? 'Congratulations! You have fully paid your loan.'
            : 'We have received your repayment. Outstanding balance is ${_formatUgx(remainingAfterPayment)}.',
        'type': 'loan',
        'isRead': 0,
        'createdAt': nowIso,
      });

      if (!mounted) return;

      // Navigate to success page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionSuccessPage(
            type: 'Repayment',
            amount: _formatUgx(paidAmount),
            reference: 'RPY${DateTime.now().millisecondsSinceEpoch}',
            recipient: '$_loanType #$_loanId',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatUgx(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'UGX ${buffer.toString()}';
  }

  String _nextPaymentDateLabel() {
    final dueDate = DateTime.now().add(const Duration(days: 30));
    final day = dueDate.day.toString().padLeft(2, '0');
    final month = dueDate.month.toString().padLeft(2, '0');
    return '$day/$month/${dueDate.year}';
  }
}
