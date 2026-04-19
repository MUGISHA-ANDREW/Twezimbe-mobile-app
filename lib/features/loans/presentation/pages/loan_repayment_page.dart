import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/dashboard/presentation/pages/main_layout.dart';

class LoanRepaymentPage extends StatefulWidget {
  const LoanRepaymentPage({super.key});

  @override
  State<LoanRepaymentPage> createState() => _LoanRepaymentPageState();
}

class _LoanRepaymentPageState extends State<LoanRepaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedMethod = 'Mobile Money';
  bool _isProcessing = false;
  AppLoanData? _activeLoan;
  bool _isLoadingLoan = true;

  final List<String> _paymentMethods = [
    'Mobile Money',
    'Bank Transfer',
    'Cash Deposit',
    'Debit Card',
  ];

  @override
  void initState() {
    super.initState();
    _loadActiveLoan();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveLoan() async {
    setState(() => _isLoadingLoan = true);
    try {
      final loan = await AppDataRepository.watchActiveLoanForCurrentUser().first;
      if (mounted) {
        setState(() {
          _activeLoan = loan;
          _isLoadingLoan = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLoan = false);
      }
    }
  }

  int _parseAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatCurrency(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  int _getRemainingBalance() {
    if (_activeLoan == null) return 0;
    final balanceStr = _activeLoan!.remainingBalance.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(balanceStr) ?? 0;
  }

  Future<void> _processRepayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amountValue = _parseAmount(_amountController.text);
    if (amountValue <= 0) {
      _showErrorDialog('Please enter a valid amount greater than zero.');
      return;
    }

    final remainingBalance = _getRemainingBalance();
    if (remainingBalance <= 0) {
      _showErrorDialog('You have no outstanding loan balance.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await AppDataRepository.makeLoanRepaymentForCurrentUser(
        amountValue: amountValue,
        method: _selectedMethod,
      );

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your loan repayment of UGX ${_formatCurrency(amountValue)} has been processed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainLayout(
                          initialIndex: 0,
                          initialMessage: 'Loan repayment successful!',
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Loan Repayment'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingLoan
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loan Summary Card
                    _buildLoanSummaryCard(),

                    const SizedBox(height: 28),

                    // Payment Amount Section
                    const Text(
                      'Payment Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAmountInput(),

                    const SizedBox(height: 24),

                    // Quick Amount Buttons
                    _buildQuickAmountButtons(),

                    const SizedBox(height: 28),

                    // Payment Method Section
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodSelector(),

                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoanSummaryCard() {
    final remainingBalance = _getRemainingBalance();
    final hasActiveLoan = _activeLoan != null && 
        (_activeLoan!.status == 'Active' || _activeLoan!.status == 'Approved') &&
        remainingBalance > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasActiveLoan
              ? [AppColors.primaryBlue, AppColors.darkBlue]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasActiveLoan ? AppColors.primaryBlue : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeLoan?.type ?? 'No Active Loan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Loan ID: ${_activeLoan?.loanId ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outstanding Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeLoan?.remainingBalance ?? 'UGX 0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Next Payment',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeLoan?.nextPaymentDate ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _activeLoan?.repaymentProgress ?? '0% Paid',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Enter Amount',
        hintText: '0',
        prefixText: 'UGX ',
        prefixStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        final amount = _parseAmount(value);
        if (amount <= 0) {
          return 'Amount must be greater than zero';
        }
        return null;
      },
      onChanged: (value) {
        // Format as user types
        if (value.isNotEmpty) {
          final amount = _parseAmount(value);
          final formatted = _formatCurrency(amount);
          if (formatted != value) {
            _amountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      },
    );
  }

  Widget _buildQuickAmountButtons() {
    final remainingBalance = _getRemainingBalance();
    final quickAmounts = [
      remainingBalance ~/ 4,
      remainingBalance ~/ 2,
      (remainingBalance * 0.75).toInt(),
      remainingBalance,
    ].where((amount) => amount > 0).toList();

    if (quickAmounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quickAmounts.map((amount) {
            final isFullPayment = amount == remainingBalance;
            return InkWell(
              onTap: () {
                _amountController.text = _formatCurrency(amount);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isFullPayment
                      ? AppColors.successGreen.withValues(alpha: 0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isFullPayment
                        ? AppColors.successGreen
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFullPayment) ...[
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.successGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isFullPayment
                          ? 'Pay Full (UGX ${_formatCurrency(amount)})'
                          : 'UGX ${_formatCurrency(amount)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFullPayment
                            ? AppColors.successGreen
                            : AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = _selectedMethod == method;
        IconData icon;
        switch (method) {
          case 'Mobile Money':
            icon = Icons.phone_android;
            break;
          case 'Bank Transfer':
            icon = Icons.account_balance;
            break;
          case 'Cash Deposit':
            icon = Icons.money;
            break;
          case 'Debit Card':
            icon = Icons.credit_card;
            break;
          default:
            icon = Icons.payment;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() => _selectedMethod = method);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isSelected
                              ? AppColors.primaryBlue
                              : Colors.grey.shade400)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? AppColors.primaryBlue
                          : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      method,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processRepayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Process Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
