import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppTransactionData>>(
      stream: AppDataRepository.watchRecentTransactionsForCurrentUser(
        limit: 200,
      ),
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? const <AppTransactionData>[];
        final moneyIn = allTransactions.where((tx) => tx.isCredit).toList();
        final moneyOut = allTransactions.where((tx) => !tx.isCredit).toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Transactions'),
              centerTitle: true,
              automaticallyImplyLeading: false,
              bottom: const TabBar(
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primaryBlue,
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Money In'),
                  Tab(text: 'Money Out'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildTransactionList(allTransactions),
                _buildTransactionList(moneyIn),
                _buildTransactionList(moneyOut),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(List<AppTransactionData> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No transactions yet',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      children: transactions.map((tx) {
        final Color color = tx.isCredit ? AppColors.successGreen : Colors.red;
        return _buildTxTile(
          tx.isCredit ? Icons.download : Icons.send,
          color,
          tx.title,
          tx.subtitle,
          tx.amount,
          tx.isCredit,
        );
      }).toList(),
    );
  }

  Widget _buildTxTile(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    String amount,
    bool isCredit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isCredit ? AppColors.successGreen : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}
