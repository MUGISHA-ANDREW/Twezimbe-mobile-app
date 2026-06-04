import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';

class AdminLoanProductsPage extends StatefulWidget {
  const AdminLoanProductsPage({super.key});

  @override
  State<AdminLoanProductsPage> createState() => _AdminLoanProductsPageState();
}

class _AdminLoanProductsPageState extends State<AdminLoanProductsPage> {
  final _repo = AdminLocalRepository();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final products = await _repo.getLoanProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  String _str(dynamic v) => v?.toString().trim() ?? '';
  int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(_str(v)) ?? 0;
  }

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

  void _snack(String msg, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError
              ? AppColors.errorRed
              : isSuccess
                  ? AppColors.successGreen
                  : AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showProductDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(
      text: existing != null ? _str(existing['name']) : '',
    );
    final amountCtrl = TextEditingController(
      text: existing != null ? _int(existing['max_amount_value']).toString() : '',
    );
    final rateCtrl = TextEditingController(
      text: existing != null
          ? (_int(existing['interest_rate_bps']) / 100).toStringAsFixed(1)
          : '',
    );
    final periodsCtrl = TextEditingController(
      text: existing != null ? _str(existing['periods']) : '3 months, 6 months, 12 months',
    );
    bool isActive = existing != null ? (existing['is_active'] == true) : true;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? 'New Loan Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Product Name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Max Amount (UGX)'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n <= 0 ? 'Enter a valid amount' : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                          hintText: 'e.g. 5.5',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return n == null || n < 0
                              ? 'Enter a valid rate'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: periodsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Available Periods',
                          hintText: 'e.g. 3 months, 6 months, 12 months',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Active'),
                          const Spacer(),
                          Switch(
                            value: isActive,
                            onChanged: (v) => setLocal(() => isActive = v),
                            activeThumbColor: AppColors.successGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    final ratePct = double.tryParse(rateCtrl.text) ?? 0;
                    final rateBps = (ratePct * 100).round();
                    if (existing == null) {
                      await _repo.createLoanProduct(
                        name: nameCtrl.text.trim(),
                        maxAmountValue:
                            int.tryParse(amountCtrl.text.trim()) ?? 0,
                        interestRateBps: rateBps,
                        periods: periodsCtrl.text.trim(),
                        isActive: isActive,
                      );
                      _snack('Product created.', isSuccess: true);
                    } else {
                      await _repo.updateLoanProduct(
                        _str(existing['id']),
                        name: nameCtrl.text.trim(),
                        maxAmountValue:
                            int.tryParse(amountCtrl.text.trim()) ?? 0,
                        interestRateBps: rateBps,
                        periods: periodsCtrl.text.trim(),
                        isActive: isActive,
                      );
                      _snack('Product updated.', isSuccess: true);
                    }
                    await _load();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _delete(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Delete "${_str(product['name'])}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.deleteLoanProduct(_str(product['id']));
    _snack('Product deleted.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header bar
        Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const Text(
                'Loan Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showProductDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Product'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: _products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) => _tile(_products[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _tile(Map<String, dynamic> p) {
    final name = _str(p['name']);
    final maxAmt = _int(p['max_amount_value']);
    final rateBps = _int(p['interest_rate_bps']);
    final ratePct = (rateBps / 100).toStringAsFixed(1);
    final periods = _str(p['periods']);
    final isActive = p['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      '$ratePct% interest • Max ${_fmt(maxAmt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.successGreen.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive
                        ? AppColors.successGreen
                        : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (periods.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Periods: $periods',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showProductDialog(existing: p),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                ),
              ),
              TextButton.icon(
                onPressed: () => _delete(p),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No loan products yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "New Product" to create your first loan product.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
