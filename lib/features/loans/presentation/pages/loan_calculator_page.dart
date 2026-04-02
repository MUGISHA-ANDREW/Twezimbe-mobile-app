import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:twezimbeapp/core/theme/app_theme.dart';

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final TextEditingController _principalController = TextEditingController(
    text: '2000000',
  );
  final TextEditingController _interestController = TextEditingController(
    text: '12',
  );
  final TextEditingController _termController = TextEditingController(
    text: '12',
  );

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    _termController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double principal = _parseDouble(_principalController.text);
    final double annualRatePercent = _parseDouble(_interestController.text);
    final int months = _parseInt(_termController.text);

    final _LoanEstimate estimate = _calculateEstimate(
      principal: principal,
      annualRatePercent: annualRatePercent,
      months: months,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Calculator'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildInputCard(
            title: 'Loan Amount (UGX)',
            hintText: 'e.g. 2000000',
            controller: _principalController,
          ),
          const SizedBox(height: 12),
          _buildInputCard(
            title: 'Annual Interest Rate (%)',
            hintText: 'e.g. 12',
            controller: _interestController,
          ),
          const SizedBox(height: 12),
          _buildInputCard(
            title: 'Repayment Term (Months)',
            hintText: 'e.g. 12',
            controller: _termController,
          ),
          const SizedBox(height: 20),
          _buildResultCard(estimate),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'Estimate your monthly repayment, total payable amount, and interest before applying for a loan.',
        style: TextStyle(fontSize: 13, color: AppColors.darkBlue, height: 1.4),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }

  Widget _buildResultCard(_LoanEstimate estimate) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Repayment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _resultRow('Monthly Payment', _formatUgx(estimate.monthlyPayment)),
          const SizedBox(height: 10),
          _resultRow('Total Interest', _formatUgx(estimate.totalInterest)),
          const SizedBox(height: 10),
          _resultRow('Total Payable', _formatUgx(estimate.totalPayable)),
          const SizedBox(height: 14),
          Text(
            estimate.warningMessage,
            style: TextStyle(
              color: estimate.warningMessage.isEmpty
                  ? Colors.transparent
                  : AppColors.errorRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }

  _LoanEstimate _calculateEstimate({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    if (principal <= 0 || annualRatePercent < 0 || months <= 0) {
      return const _LoanEstimate(
        monthlyPayment: 0,
        totalInterest: 0,
        totalPayable: 0,
        warningMessage:
            'Please enter valid values greater than zero for amount and months.',
      );
    }

    final double monthlyRate = annualRatePercent / 12 / 100;

    if (monthlyRate == 0) {
      final double monthlyPayment = _roundToUnit(principal / months);
      final double totalPayable = monthlyPayment * months;
      final double totalInterest = totalPayable - principal;
      return _LoanEstimate(
        monthlyPayment: monthlyPayment,
        totalInterest: totalInterest,
        totalPayable: totalPayable,
      );
    }

    final double power = math.pow(1 + monthlyRate, months).toDouble();
    final double exactMonthlyPayment =
        principal * monthlyRate * power / (power - 1);
    final double monthlyPayment = _roundToUnit(exactMonthlyPayment);
    final double totalPayable = monthlyPayment * months;
    final double totalInterest = totalPayable - principal;

    return _LoanEstimate(
      monthlyPayment: monthlyPayment,
      totalInterest: totalInterest,
      totalPayable: totalPayable,
    );
  }

  double _roundToUnit(double value) {
    return value.roundToDouble();
  }

  String _formatUgx(double value) {
    final int rounded = value.round();
    final String digits = rounded.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    final String sign = rounded < 0 ? '-' : '';
    return '${sign}UGX ${buffer.toString()}';
  }

  double _parseDouble(String value) {
    final sanitized = value.replaceAll(',', '').trim();
    return double.tryParse(sanitized) ?? 0;
  }

  int _parseInt(String value) {
    final sanitized = value.replaceAll(',', '').trim();
    return int.tryParse(sanitized) ?? 0;
  }
}

class _LoanEstimate {
  const _LoanEstimate({
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalPayable,
    this.warningMessage = '',
  });

  final double monthlyPayment;
  final double totalInterest;
  final double totalPayable;
  final String warningMessage;
}
