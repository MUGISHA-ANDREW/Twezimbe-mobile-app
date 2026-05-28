import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  String _filter = 'All'; // All | Credit | Debit
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsFull = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown date';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${_months[dt.month]} ${dt.year}, $h:$min $period';
  }

  String _groupLabel(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDay = DateTime(dt.year, dt.month, dt.day);
    if (txDay == today) return 'Today';
    if (txDay == yesterday) return 'Yesterday';
    if (now.difference(dt).inDays < 7) return _weekdays[dt.weekday];
    return '${_monthsFull[dt.month]} ${dt.year}';
  }

  List<AppTransactionData> _applyFilters(List<AppTransactionData> all) {
    return all.where((tx) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Credit' && tx.isCredit) ||
          (_filter == 'Debit' && !tx.isCredit);
      if (!matchesFilter) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return tx.title.toLowerCase().contains(q) ||
          tx.amount.toLowerCase().contains(q) ||
          tx.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Transactions'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<List<AppTransactionData>>(
        stream: AppDataRepository.watchRecentTransactionsForCurrentUser(
          limit: 500,
        ),
        builder: (context, snapshot) {
          final all = _applyFilters(snapshot.data ?? []);

          // Group by label
          final Map<String, List<AppTransactionData>> grouped = {};
          for (final tx in all) {
            final label = _groupLabel(tx.createdAt);
            grouped.putIfAbsent(label, () => []).add(tx);
          }
          final groupKeys = grouped.keys.toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search transactions…',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: ['All', 'Credit', 'Debit'].map((f) {
                    final selected = _filter == f;
                    Color chipColor;
                    if (f == 'Credit') {
                      chipColor = AppColors.successGreen;
                    } else if (f == 'Debit') {
                      chipColor = AppColors.errorRed;
                    } else {
                      chipColor = AppColors.primaryBlue;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f),
                        selected: selected,
                        selectedColor: chipColor.withValues(alpha: 0.15),
                        checkmarkColor: chipColor,
                        labelStyle: TextStyle(
                          color: selected ? chipColor : Colors.grey.shade600,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: selected ? chipColor : Colors.grey.shade300,
                        ),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Transactions list
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting &&
                        snapshot.data == null
                    ? const Center(child: CircularProgressIndicator())
                    : all.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: groupKeys.length,
                            itemBuilder: (context, gi) {
                              final label = groupKeys[gi];
                              final txs = grouped[label]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  ...txs.map((tx) => _buildTile(tx)),
                                ],
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primaryBlue,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filter != 'All'
                ? 'No matching transactions'
                : 'No transactions yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty || _filter != 'All'
                ? 'Try a different search or filter'
                : 'Your transaction history will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(AppTransactionData tx) {
    final isCredit = tx.isCredit;
    final color = isCredit ? AppColors.successGreen : AppColors.errorRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textMain,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  tx.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _formatDate(tx.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}${tx.amount}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ),
    );
  }
}
