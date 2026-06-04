import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/core/widgets/processing_payment_dialog.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/transaction_success_page.dart';

class MakePaymentPage extends StatefulWidget {
  const MakePaymentPage({super.key});

  @override
  State<MakePaymentPage> createState() => _MakePaymentPageState();
}

class _MakePaymentPageState extends State<MakePaymentPage> {
  static SupabaseClient get _sb => Supabase.instance.client;

  String _selectedMethod = 'MTN Mobile Money';
  bool _payFullInstallment = true;
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _isProcessingDialogVisible = false;

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
    final user = _sb.auth.currentUser;
    if (user == null) return;

    // Query Supabase directly — no SQLite involved
    Map<String, dynamic>? row;
    try {
      // Prefer an Active loan; fall back to the most recent one
      row = await _sb
          .from('loans')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Active')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) {}

    if (row == null) {
      try {
        row = await _sb
            .from('loans')
            .select()
            .eq('user_id', user.id)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (_) {}
    }

    if (row == null || !mounted) return;

    final remaining = (row['remaining_balance_value'] as num?)?.toInt() ?? 0;
    setState(() {
      _loanType = (row!['loan_type'] as String?)?.trim().isNotEmpty == true
          ? row['loan_type'] as String
          : 'Salary Loan';
      _remainingBalance = remaining;
      _loanId = (row['loan_id'] as String?)?.trim().isNotEmpty == true
          ? row['loan_id'] as String
          : '-';
      _nextPaymentDate =
          (row['next_payment_date'] as String?)?.trim().isNotEmpty == true
              ? row['next_payment_date'] as String
              : 'TBD';

      if (_remainingBalance <= 0) {
        _nextInstallmentAmount = 0;
      } else {
        _nextInstallmentAmount = (_remainingBalance * 0.05).ceil();
        if (_nextInstallmentAmount < 10000) _nextInstallmentAmount = 10000;
      }
    });
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

  void _showProcessingDialog() {
    if (!mounted || _isProcessingDialogVisible) {
      return;
    }
    _isProcessingDialogVisible = true;

    showProcessingPaymentDialog(context).whenComplete(() {
      _isProcessingDialogVisible = false;
    });
  }

  void _hideProcessingDialog() {
    if (!mounted || !_isProcessingDialogVisible) {
      return;
    }
    hideProcessingPaymentDialog(context);
    _isProcessingDialogVisible = false;
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
    _showProcessingDialog();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw StateError('No authenticated user found.');
      }

      final amountToApply =
          _paymentAmount; // Simplified, repository handles capping

      // Use the Repository for atomic Firestore + Local DB sync
      await AppDataRepository.repayLoan(amount: amountToApply, loanId: _loanId);

      if (!mounted) return;

      _hideProcessingDialog();

      // Navigate to success page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionSuccessPage(
            type: 'Repayment',
            amount: _formatUgx(amountToApply),
            reference: 'RPY${DateTime.now().millisecondsSinceEpoch}',
            recipient: '$_loanType #$_loanId',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _hideProcessingDialog();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      if (mounted) {
        _hideProcessingDialog();
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
}
