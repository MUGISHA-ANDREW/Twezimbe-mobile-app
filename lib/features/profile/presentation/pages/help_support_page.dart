import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/chatbot/presentation/pages/chatbot_page.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppFaqData> _filteredFaqs() {
    final allFaqs = AppDataRepository.faqs;
    if (_query.trim().isEmpty) {
      return allFaqs;
    }

    final query = _query.toLowerCase();
    return allFaqs
        .where((faq) {
          return faq.question.toLowerCase().contains(query) ||
              faq.answer.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _copyToClipboard(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final support = AppDataRepository.support;
    final filteredFaqs = _filteredFaqs();

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
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
              support.phone,
              AppColors.primaryBlue,
              () => _copyToClipboard(support.phone, 'Phone number'),
            ),
            _buildContactTile(
              Icons.email_outlined,
              'Email',
              support.email,
              AppColors.primaryOrange,
              () => _copyToClipboard(support.email, 'Support email'),
            ),
            _buildContactTile(
              Icons.chat_outlined,
              'Live Chat',
              support.liveChatHours,
              AppColors.successGreen,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatbotPage()),
                );
              },
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
            if (filteredFaqs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: const Text('No FAQs match your search.'),
              )
            else
              ...filteredFaqs.map(
                (faq) => _buildFaqTile(faq.question, faq.answer),
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
                  _buildInfoRow('Version', support.appVersion),
                  const Divider(height: 24),
                  _buildInfoRow('Build', support.buildNumber),
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
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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
