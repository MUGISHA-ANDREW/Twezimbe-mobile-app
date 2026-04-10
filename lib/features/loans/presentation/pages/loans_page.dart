import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/apply_loan_page.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/loan_calculator_page.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/loan_details_page.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/make_payment_page.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh UI every 30 seconds to update relative time labels
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  AppLoanData get _fallbackLoan => const AppLoanData(
    type: 'No Active Loan',
    loanId: 'N/A',
    status: 'None',
    remainingBalance: 'UGX 0',
    nextPaymentDate: 'Not scheduled',
    repaymentProgress: '0%',
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppLoanData>(
      stream: AppDataRepository.watchActiveLoanForCurrentUser(),
      builder: (context, loanSnapshot) {
        final loan = loanSnapshot.data ?? _fallbackLoan;
        final outstandingBalance =
            int.tryParse(
              loan.remainingBalance.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
        final canMakePayment =
            (loan.status == 'Active' || loan.status == 'Approved') &&
            outstandingBalance > 0;

        return StreamBuilder<List<AppLoanApplicationData>>(
          stream: AppDataRepository.watchLoanApplicationsForCurrentUser(
            limit: 200,
          ),
          builder: (context, txSnapshot) {
            final loanHistory =
                txSnapshot.data ?? const <AppLoanApplicationData>[];

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('My Loans'),
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      tooltip: 'Loan calculator',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoanCalculatorPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calculate_outlined),
                    ),
                  ],
                  bottom: const TabBar(
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryBlue,
                    tabs: [
                      Tab(text: 'Active'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildActiveLoanCard(context, loan),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: canMakePayment
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MakePaymentPage(),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(
                            canMakePayment ? 'Make Payment' : 'No Payment Due',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApplyLoanPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Apply for a New Loan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    _buildHistoryTab(loanHistory),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveLoanCard(BuildContext context, AppLoanData loan) {
    final progressPercent =
        int.tryParse(
          loan.repaymentProgress.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoanDetailsPage(loan: loan)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loan.type,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    loan.status,
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${loan.loanId}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining Balance',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan.remainingBalance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan.nextPaymentDate,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryBlue,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              loan.repaymentProgress,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(List<AppLoanApplicationData> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No loan history found.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final app = history[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: AppColors.primaryBlue,
            ),
            title: Text(
              app.loanType,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${app.period} - ${_getRelativeTime(app.createdAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  app.amount,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: app.status == 'Approved'
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : app.status == 'Rejected'
                        ? AppColors.errorRed.withValues(alpha: 0.1)
                        : AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    app.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: app.status == 'Approved'
                          ? AppColors.successGreen
                          : app.status == 'Rejected'
                          ? AppColors.errorRed
                          : AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
