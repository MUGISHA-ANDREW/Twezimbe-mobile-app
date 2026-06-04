import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_transaction_model.dart';

class AdminTransactionsPage extends StatefulWidget {
  const AdminTransactionsPage({super.key});

  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage> {
  final _repo = AdminLocalRepository();
  List<AdminTransactionModel> _all = [];
  bool _isLoading = false;
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(
      () => setState(() => _search = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final txs = await _repo.getAllTransactions(limit: 300);
    if (mounted) {
      setState(() {
        _all = txs;
        _isLoading = false;
      });
    }
  }

  List<AdminTransactionModel> get _filtered {
    return _all.where((tx) {
      if (_filter == 'Credit' && !tx.isCredit) return false;
      if (_filter == 'Debit' && tx.isCredit) return false;
      if (_search.isNotEmpty) {
        return tx.title.toLowerCase().contains(_search) ||
            tx.userId.toLowerCase().contains(_search);
      }
      return true;
    }).toList();
  }

  int get _totalCredit => _filtered
      .where((t) => t.isCredit)
      .fold(0, (s, t) => s + t.amountValue);
  int get _totalDebit => _filtered
      .where((t) => !t.isCredit)
      .fold(0, (s, t) => s + t.amountValue);

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final from = s.length - i;
      buf.write(s[i]);
      if (from > 1 && from % 3 == 1) buf.write(',');
    }
    return 'UGX ${buf.toString()}';
  }

  String _date(DateTime? dt) {
    if (dt == null) return '-';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day}/${dt.month}/${dt.year} $h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;

    return Column(
      children: [
        // Totals bar
        Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _summaryChip(
                'In',
                _fmt(_totalCredit),
                AppColors.successGreen,
                Icons.arrow_downward,
              ),
              const SizedBox(width: 10),
              _summaryChip(
                'Out',
                _fmt(_totalDebit),
                AppColors.errorRed,
                Icons.arrow_upward,
              ),
            ],
          ),
        ),

        // Search + filter
        Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by title or user ID…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _searchCtrl.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['All', 'Credit', 'Debit'].map((f) {
                  final sel = _filter == f;
                  Color c = f == 'Credit'
                      ? AppColors.successGreen
                      : f == 'Debit'
                          ? AppColors.errorRed
                          : AppColors.primaryBlue;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: sel,
                      selectedColor: c.withValues(alpha: 0.15),
                      checkmarkColor: c,
                      labelStyle: TextStyle(
                        color: sel ? c : Colors.grey.shade600,
                        fontWeight:
                            sel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : visible.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) => _tile(visible[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _tile(AdminTransactionModel tx) {
    final color =
        tx.isCredit ? AppColors.successGreen : AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE5F3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _date(tx.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '-'}${_fmt(tx.amountValue)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No transactions found',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
