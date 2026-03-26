import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            _buildTransactionList(),
            _buildMoneyInList(),
            _buildMoneyOutList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Today',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
        ),
        _buildTxTile(
          Icons.send,
          Colors.red,
          'Sent to Maliro Stephen',
          'Transfer â€¢ 10:24 AM',
          '- UGX 100,000',
          false,
        ),

        const Padding(
          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            'Yesterday',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
        ),
        _buildTxTile(
          Icons.download,
          AppColors.successGreen,
          'Received from Lubega S',
          'Deposit â€¢ 02:30 PM',
          '+ UGX 80,000',
          true,
        ),
        _buildTxTile(
          Icons.credit_card,
          AppColors.primaryOrange,
          'Loan Repayment',
          'Auto deduct â€¢ 09:00 AM',
          '- UGX 230,000',
          false,
        ),

        const Padding(
          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            'Nov 12, 2025',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
        ),
        _buildTxTile(
          Icons.account_balance,
          AppColors.primaryBlue,
          'Loan Disbursed',
          'Salary Loan',
          '+ UGX 1,300,000',
          true,
        ),
      ],
    );
  }

  Widget _buildMoneyInList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      children: [
        _buildTxTile(
          Icons.download,
          AppColors.successGreen,
          'Received from Lubega S',
          'Deposit â€¢ Yesterday, 02:30 PM',
          '+ UGX 80,000',
          true,
        ),
        _buildTxTile(
          Icons.account_balance,
          AppColors.primaryBlue,
          'Loan Disbursed',
          'Salary Loan â€¢ Nov 12',
          '+ UGX 1,300,000',
          true,
        ),
      ],
    );
  }

  Widget _buildMoneyOutList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      children: [
        _buildTxTile(
          Icons.send,
          Colors.red,
          'Sent to Maliro Stephen',
          'Transfer â€¢ Today, 10:24 AM',
          '- UGX 100,000',
          false,
        ),
        _buildTxTile(
          Icons.credit_card,
          AppColors.primaryOrange,
          'Loan Repayment',
          'Auto deduct â€¢ Yesterday, 09:00 AM',
          '- UGX 230,000',
          false,
        ),
      ],
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
