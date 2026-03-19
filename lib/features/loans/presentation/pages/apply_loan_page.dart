import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/loan_application_success_page.dart';

class ApplyLoanPage extends StatefulWidget {
  const ApplyLoanPage({super.key});

  @override
  State<ApplyLoanPage> createState() => _ApplyLoanPageState();
}

class _ApplyLoanPageState extends State<ApplyLoanPage> {
  String _selectedPeriod = '6 months';
  bool _acceptedTerms = false;

  final List<String> _periods = [
    '6 months',
    '12 months',
    '18 months',
    '24 months',
    '30 months',
    '36 months',
    '42 months',
    '48 months',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for a loan'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                const Text(
                  'NAMUGUMYA AGNES',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'AC00000001',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Loan type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: 'Salary loan',
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              items: [
                'Salary loan',
                'Business loan',
                'Emergency loan',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {},
            ),
            const SizedBox(height: 24),
            const Text(
              'Loan amount in UGX',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter loan amount e.g 500,000',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Repayment period',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _periods.map((period) {
                final isSelected = _selectedPeriod == period;
                return ChoiceChip(
                  label: Text(period),
                  selected: isSelected,
                  selectedColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMain,
                  ),
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loan purpose',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: 'Farming',
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              items: [
                'Farming',
                'Education',
                'Business',
                'Medical',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {},
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      _acceptedTerms = val ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'By checking this box, I confirm that I have read and accepted the ',
                          ),
                          TextSpan(
                            text: 'terms and conditions',
                            style: TextStyle(color: AppColors.primaryBlue),
                          ),
                          const TextSpan(text: ' of loan applications.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _acceptedTerms
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoanApplicationSuccessPage(),
                        ),
                      );
                    }
                  : null,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
