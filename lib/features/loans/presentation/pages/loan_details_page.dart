import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/make_payment_page.dart';
import 'package:twezimbeapp/features/notifications/presentation/pages/notifications_page.dart';

class LoanDetailsPage extends StatelessWidget {
  const LoanDetailsPage({super.key, this.loan});

  final AppLoanData? loan;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppLoanData>(
      stream: AppDataRepository.watchActiveLoanForCurrentUser(),
      builder: (context, snapshot) {
        final loanData =
            snapshot.data ??
            loan ??
            AppDataRepository.activeLoanForCurrentUser();
        final progressPercent =
            int.tryParse(
              loanData.repaymentProgress.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
        final monthlyInstallment = _estimateInstallment(
          loanData.remainingBalance,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Loan Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_active,
                  color: AppColors.primaryOrange,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Loan Overview Card
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Loan Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loan ID - ${loanData.loanId}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            Icons.credit_card,
                            'Loan type',
                            loanData.type,
                          ),
                          _buildInfoColumn(
                            Icons.calendar_today,
                            'Next Payment',
                            loanData.nextPaymentDate,
                          ),
                          _buildInfoColumn(
                            Icons.account_balance_wallet,
                            'Status',
                            loanData.status,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Financial Details Card
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFinancialRow(
                        'Amount borrowed',
                        loanData.remainingBalance,
                      ),
                      const SizedBox(height: 8),
                      _buildFinancialRow(
                        'Monthly installment',
                        monthlyInstallment,
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Remaining Balance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercent / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryOrange,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Repayment Schedule
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Repayment Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildScheduleRow(
                        loanData.nextPaymentDate,
                        monthlyInstallment,
                        false,
                      ),
                      const Divider(),
                      _buildScheduleRow(
                        'Next cycle',
                        monthlyInstallment,
                        false,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MakePaymentPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                        ),
                        child: const Text('Make Payment'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                        ),
                        child: const Text('Download statement'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _estimateInstallment(String remainingBalance) {
    final int value =
        int.tryParse(remainingBalance.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final int installment = (value / 6).round();
    return AppDataRepository.formatUgx(installment);
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: child,
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String date, String amount, bool isPaid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(amount, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          Row(
            children: [
              Icon(
                isPaid ? Icons.check_circle_outline : Icons.hourglass_bottom,
                color: isPaid ? AppColors.successGreen : AppColors.darkBlue,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                isPaid ? 'Paid' : 'Pending',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPaid ? AppColors.successGreen : AppColors.darkBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
