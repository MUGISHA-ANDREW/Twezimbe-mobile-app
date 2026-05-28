import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';

class AdminCreateLoanPage extends StatefulWidget {
  const AdminCreateLoanPage({super.key});

  @override
  State<AdminCreateLoanPage> createState() => _AdminCreateLoanPageState();
}

class _AdminCreateLoanPageState extends State<AdminCreateLoanPage> {
  final _repo = AdminLocalRepository();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _searchController = TextEditingController();

  List<AdminUserModel> _allUsers = [];
  List<AdminUserModel> _filteredUsers = [];
  AdminUserModel? _selectedUser;
  String _loanType = 'Personal Loan';
  String _period = '3 months';
  bool _isLoading = false;
  bool _isSubmitting = false;

  static const _loanTypes = [
    'Personal Loan',
    'Business Loan',
    'Emergency Loan',
    'Education Loan',
    'Agriculture Loan',
  ];
  static const _periods = [
    '1 month',
    '3 months',
    '6 months',
    '12 months',
    '24 months',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _repo.getUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredUsers = q.isEmpty
          ? _allUsers
          : _allUsers.where((u) {
              return u.fullName.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q);
            }).toList();
    });
  }

  int _parseAmount() {
    return int.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
  }

  Future<void> _submit() async {
    if (_selectedUser == null) {
      _snack('Please select a user.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount();
    if (amount <= 0) {
      _snack('Enter a valid amount.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repo.createLoanForUser(
        userId: _selectedUser!.id,
        amountValue: amount,
        loanType: _loanType,
        period: _period,
        purpose: _purposeController.text.trim(),
      );
      if (!mounted) return;
      _snack(
        'Loan of UGX ${_fmt(amount)} issued to ${_selectedUser!.fullName}.',
        isSuccess: true,
      );
      _formKey.currentState!.reset();
      _amountController.clear();
      _purposeController.clear();
      setState(() => _selectedUser = null);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Issue Loan Directly',
              'Create a loan for any registered user without requiring an application.',
              Icons.add_circle_outline,
              AppColors.primaryBlue,
            ),
            const SizedBox(height: 20),

            // User picker
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF4F8FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_filteredUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No users found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.grey.shade100, height: 1),
                        itemBuilder: (context, i) {
                          final u = _filteredUsers[i];
                          final selected = _selectedUser?.id == u.id;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primaryBlue.withValues(alpha: 0.12),
                              child: Text(
                                u.fullName.isNotEmpty
                                    ? u.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              u.fullName.isEmpty ? 'No name' : u.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              u.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.successGreen,
                                  )
                                : null,
                            tileColor: selected
                                ? AppColors.primaryBlue.withValues(alpha: 0.05)
                                : null,
                            onTap: () => setState(() => _selectedUser = u),
                          );
                        },
                      ),
                    ),
                  if (_selectedUser != null) ...[
                    const Divider(),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.successGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected: ${_selectedUser!.fullName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loan details
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Loan type
                  DropdownButtonFormField<String>(
                    initialValue: _loanType,
                    decoration: const InputDecoration(
                      labelText: 'Loan Type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _loanTypes
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _loanType = v!),
                  ),
                  const SizedBox(height: 14),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (UGX)',
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'e.g. 500000',
                    ),
                    validator: (v) {
                      final amt = int.tryParse(
                        (v ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (amt == null || amt <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Period
                  DropdownButtonFormField<String>(
                    initialValue: _period,
                    decoration: const InputDecoration(
                      labelText: 'Repayment Period',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: _periods
                        .map(
                          (p) => DropdownMenuItem(value: p, child: Text(p)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _period = v!),
                  ),
                  const SizedBox(height: 14),

                  // Purpose
                  TextFormField(
                    controller: _purposeController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      prefixIcon: Icon(Icons.notes_outlined),
                      hintText: 'Briefly describe the purpose of the loan',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isSubmitting ? 'Processing…' : 'Issue Loan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
