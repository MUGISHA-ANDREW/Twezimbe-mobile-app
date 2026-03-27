import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class LoanApplicationSuccessPage extends StatelessWidget {
  const LoanApplicationSuccessPage({
    super.key,
    required this.applicationId,
    required this.loanType,
    required this.amount,
    required this.period,
    required this.status,
  });

  final String applicationId;
  final String loanType;
  final String amount;
  final String period;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Success illustration
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    size: 56,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Application Submitted!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your loan application has been submitted successfully and is now under review. You will be notified once a decision is made.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Application summary
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRow('Application ID', applicationId),
                    const Divider(height: 24),
                    _buildRow('Loan Type', loanType),
                    const Divider(height: 24),
                    _buildRow('Amount', amount),
                    const Divider(height: 24),
                    _buildRow('Period', period),
                    const Divider(height: 24),
                    _buildRow('Status', status),
                  ],
                ),
              ),
              const Spacer(),

              // Timeline note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Applications are typically reviewed within 24-48 hours.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
