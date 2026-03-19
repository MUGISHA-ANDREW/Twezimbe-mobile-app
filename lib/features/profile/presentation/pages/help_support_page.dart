import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactTile(
              Icons.phone_outlined,
              'Call Us',
              '+256 700 000 000',
              AppColors.primaryBlue,
            ),
            _buildContactTile(
              Icons.email_outlined,
              'Email',
              'support@twezimbe.co.ug',
              AppColors.primaryOrange,
            ),
            _buildContactTile(
              Icons.chat_outlined,
              'Live Chat',
              'Available 8AM - 6PM',
              AppColors.successGreen,
            ),
            const SizedBox(height: 32),

            const Text(
              'FAQs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqTile(
              'How do I apply for a loan?',
              'To apply for a loan, open the app and navigate to the "Loans" section. Tap "Apply Now", select your desired loan amount and repayment period, then complete the application form. Ensure your profile is fully verified before applying to avoid delays.',
            ),
            _buildFaqTile(
              'How long does loan approval take?',
              'Loan applications are reviewed and approved within 24 hours. In some cases, additional verification may be required, which can take up to 48 hours. You will receive a notification via SMS and in-app once a decision has been made.',
            ),
            _buildFaqTile(
              'What are the repayment options?',
              'We offer flexible repayment options including weekly, bi-weekly, and monthly schedules. Repayments can be made via mobile money (MTN or Airtel), bank transfer, or directly through the app. You can also set up automatic repayments to avoid missing due dates.',
            ),
            _buildFaqTile(
              'How do I reset my password?',
              'On the login screen, tap "Forgot Password?" and enter your registered email address or phone number. You will receive a one-time code to verify your identity. Once verified, you can set a new password. If you continue to experience issues, contact our support team.',
            ),
            _buildFaqTile(
              'Is my data secure?',
              'Yes. Twezimbe uses industry-standard encryption (AES-256) to protect all your personal and financial data. We never share your information with third parties without your consent. Our systems are regularly audited to ensure compliance with data protection regulations.',
            ),
            const SizedBox(height: 32),

            const Text(
              'App Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Version', '1.0.0'),
                  const Divider(height: 24),
                  _buildInfoRow('Build', '2026.03.08'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}