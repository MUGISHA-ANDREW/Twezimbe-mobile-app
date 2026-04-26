import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/core/widgets/processing_payment_dialog.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  String _selectedMethod = 'MTN Mobile Money';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;
  bool _isProcessingDialogVisible = false;

  AppProfileData get _fallbackProfile => const AppProfileData(
    fullName: 'User',
    email: '',
    phoneNumber: 'Not set',
    dateOfBirth: 'Not set',
    nationalId: 'Not set',
    address: 'Not set',
    photoUrl: null,
    customerId: 'CUST-00000',
    kycStatus: 'KYC Verified',
    accountType: 'Savings Account',
    availableBalance: 'UGX 0',
    isAdmin: false,
  );

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int _parseAmount(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  String _maskedPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) {
      return rawPhone.trim();
    }
    final start = digits.substring(0, 3);
    final end = digits.substring(digits.length - 3);
    return '$start****$end';
  }

  String _transactionReference() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final millis = now.millisecond.toString().padLeft(3, '0');
    return 'WTH$y$m$d${now.hour}${now.minute}${now.second}$millis';
  }

  Future<void> _persistWithdrawalInBackground({
    required int amountValue,
    required String reference,
    required String maskedPhone,
  }) async {
    try {
      // This persists transaction details and creates an in-app notification.
      await AppDataRepository.addTransactionForCurrentUser(
        title: 'Withdrawal to $_selectedMethod',
        subtitle: '$maskedPhone • Ref $reference',
        amountValue: amountValue,
        isCredit: false,
      );
    } catch (_) {
      // Keep UX instant even if backend write is delayed/failed.
    }
  }

  Future<void> _submitWithdrawal() async {
    final int amountValue = _parseAmount(_amountController.text);
    if (amountValue <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }

    final String rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _showProcessingDialog();

    final String reference = _transactionReference();
    final String maskedPhone = _maskedPhone(rawPhone);

    unawaited(
      _persistWithdrawalInBackground(
        amountValue: amountValue,
        reference: reference,
        maskedPhone: maskedPhone,
      ),
    );

    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) {
        return;
      }
      _hideProcessingDialog();
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        _hideProcessingDialog();
        setState(() => _isSubmitting = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppProfileData>(
      stream: AppDataRepository.watchProfileForCurrentUser(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? _fallbackProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Withdraw Funds'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current balance info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.availableBalance,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Withdraw to
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
                        'Withdraw To',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentMethod(
                        'MTN Mobile Money',
                        Icons.phone_android,
                        const Color(0xFFFFCC00),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethod(
                        'Airtel Money',
                        Icons.phone_android,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount + Phone
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 24,
                          ),
                          prefixText: 'UGX ',
                          prefixStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Phone Number',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'e.g. 0770000000',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Withdraw'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethod(String name, IconData icon, Color color) {
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
}
