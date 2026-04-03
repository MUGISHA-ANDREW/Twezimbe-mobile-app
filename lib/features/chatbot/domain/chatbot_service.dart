import 'package:twezimbeapp/core/data/app_data_repository.dart';

class ChatbotService {
  // Greetings - maps common greeting patterns to responses
  static const Map<String, List<String>> _greetings = {
    'hello': [
      'Hello! 👋 How can I help you today?',
      'Hi there! 😊 What can I assist you with?',
      'Hey! Welcome to Twezimbe! How can I help?',
    ],
    'hi': [
      'Hi! 👋 How can I help you today?',
      'Hello! 😊 What can I assist you with?',
    ],
    'hey': [
      'Hey! 😊 How can I help you today?',
      'Hey there! 👋 What can I do for you?',
    ],
    'good morning': [
      'Good morning! ☀️ How can I help you today?',
      'Good morning! Hope you have a great day! What can I assist you with?',
    ],
    'good afternoon': [
      'Good afternoon! 🌤️ How can I help you today?',
      'Good afternoon! What can I assist you with?',
    ],
    'good evening': [
      'Good evening! 🌙 How can I help you today?',
      'Good evening! What can I assist you with?',
    ],
    'how are you': [
      "I'm doing great, thank you for asking! 😊 How can I help you today?",
      "I'm doing well! Ready to assist you. What do you need help with?",
    ],
    'who are you': [
      "I'm the Twezimbe Assistant! 🤖 I'm here to help you with questions about the app, loans, savings, and more. What would you like to know?",
      "I'm your helpful assistant for Twezimbe! I can answer questions about loans, savings, repayments, and how to use the app. Just ask!",
    ],
    'help': [
      "I can help you with:\n\n• Loan applications and repayments\n• Account information\n• How to use the app\n• Security settings\n• And more!\n\nJust ask me a question! 😊",
      "I'm here to help! You can ask me about:\n\n📋 Loans - applying, repaying, status\n💰 Savings and balance\n🔐 Account security\n📱 How to use the app\n\nWhat would you like to know?",
    ],
    'thanks': [
      "You're welcome! 😊 Happy to help!",
      'Glad I could help! Let me know if you have more questions.',
      "No problem! Feel free to ask if you need anything else.",
    ],
    'thank you': [
      "You're welcome! 😊 Happy to help!",
      'Glad I could help! Let me know if you have more questions.',
      "No problem! Feel free to ask if you need anything else.",
    ],
  };

  static const String _defaultGreetingResponse =
      "Hello! 👋 Welcome to Twezimbe! I'm here to help. You can ask me about loans, savings, account info, or how to use the app. What would you like to know?";

  static const String _outOfScopeResponse =
      "I'm not quite sure about that. 😅\n\nTry asking about:\n• Loan applications or repayments\n• Your account balance\n• How to update your profile\n• Security settings\n\nOr contact support@twezimbe.co.ug for more help.";

  String getResponse(String input) {
    final query = _normalize(input);
    if (query.isEmpty) {
      return _defaultGreetingResponse;
    }

    // Check for greetings first
    for (final entry in _greetings.entries) {
      if (query == entry.key || query.startsWith(entry.key) || query.contains(entry.key)) {
        return _getRandomResponse(entry.value);
      }
    }

    // Check for FAQ matches with enhanced matching
    final faqResponse = _matchFaq(query);
    if (faqResponse != null) {
      return faqResponse;
    }

    // Check for common keywords
    final keywordResponse = _matchKeywords(query);
    if (keywordResponse != null) {
      return keywordResponse;
    }

    return _outOfScopeResponse;
  }

  String? _matchFaq(String query) {
    // Enhanced FAQ matching with keyword detection
    for (final faq in AppDataRepository.faqs) {
      final question = _normalize(faq.question);
      
      // Exact or close match
      if (_calculateSimilarity(query, question) > 0.6) {
        return faq.answer;
      }
      
      // Check if key words from question are in query
      final questionWords = question.split(' ').where((w) => w.length > 3).toList();
      final matchedWords = questionWords.where((w) => query.contains(w)).length;
      if (questionWords.isNotEmpty && matchedWords >= questionWords.length * 0.5) {
        return faq.answer;
      }
    }
    return null;
  }

  String? _matchKeywords(String query) {
    // Loan-related keywords
    if (_containsAny(query, ['loan', 'borrow', 'credit', 'lend', 'money'])) {
      return _getLoanResponse(query);
    }
    
    // Savings-related keywords
    if (_containsAny(query, ['save', 'saving', 'deposit', 'balance', 'account'])) {
      return "Twezimbe helps you save money with your group! 💰\n\nYou can:\n• Deposit money to your account\n• Track your savings balance\n• Join group savings pools\n• Earn interest on your savings\n\nWant to know more about a specific feature?";
    }
    
    // Repayment keywords
    if (_containsAny(query, ['repay', 'repayment', 'pay', 'installment', 'due'])) {
      return "For loan repayments, you can:\n\n• Make payments through the app\n• Use mobile money\n• Set up automatic repayments\n\nGo to Loans > Repay to make a payment. Need more help?";
    }
    
    // Password/reset keywords
    if (_containsAny(query, ['password', 'reset', 'forgot', 'change password'])) {
      return "To reset your password:\n\n1. Go to the login screen\n2. Tap 'Forgot Password'\n3. Enter your email or phone number\n4. Check for a verification code\n5. Create a new password\n\nNeed help? Contact support@twezimbe.co.ug";
    }
    
    // KYC/verification keywords
    if (_containsAny(query, ['kyc', 'verify', 'verification', 'identity', 'document'])) {
      return "KYC (Know Your Customer) verification helps keep your account secure. 📋\n\nTo complete verification:\n• Go to Profile > Personal Information\n• Add your National ID number\n• Provide required documents\n\nOnce verified, you can access all features!";
    }
    
    // App/how to use keywords
    if (_containsAny(query, ['how to', 'use', 'app', 'guide', 'tutorial', 'start'])) {
      return "Here's how to get started with Twezimbe:\n\n1. 📝 Create an account with your phone/email\n2. 💰 Make your first deposit\n3. 📋 Apply for a loan if needed\n4. 💬 Chat with us anytime!\n\nNeed help with any specific feature?";
    }
    
    // Contact/support keywords
    if (_containsAny(query, ['contact', 'support', 'help', 'customer service', 'call'])) {
      return "You can reach us:\n\n📧 Email: support@twezimbe.co.ug\n📞 Phone: +256 700 000 000\n💬 Chat: We're here!\n\nOur team is available 8AM - 6PM daily.";
    }
    
    // Security keywords
    if (_containsAny(query, ['security', 'secure', 'pin', 'fingerprint', 'biometric', '2fa'])) {
      return "Keep your account secure! 🔐\n\nYou can enable:\n• Biometric login (fingerprint/face)\n• Two-factor authentication\n• Login alerts\n\nGo to Profile > Security Settings to manage these.";
    }
    
    return null;
  }

  String _getLoanResponse(String query) {
    if (_containsAny(query, ['apply', 'application', 'new', 'request'])) {
      return "To apply for a loan:\n\n1. Go to the Loans section\n2. Tap 'Apply for a New Loan'\n3. Choose loan type\n4. Enter amount and period\n5. Submit your application\n\nLoans are usually reviewed within 24 hours!";
    }
    
    if (_containsAny(query, ['status', 'approve', 'pending', 'check'])) {
      return "To check your loan status:\n\nGo to Loans > Your Loans\n\nYou'll see:\n• Pending applications\n• Active loans\n• Repayment progress\n\nMost applications are reviewed within 24 hours.";
    }
    
    return "Twezimbe offers different loan types! 💰\n\n• Salary Loans\n• Group Loans\n• Emergency Loans\n\nTo apply, go to Loans > Apply for a New Loan. Need more details?";
  }

  bool _containsAny(String query, List<String> keywords) {
    return keywords.any((keyword) => query.contains(keyword));
  }

  String _getRandomResponse(List<String> responses) {
    final index = DateTime.now().millisecondsSinceEpoch % responses.length;
    return responses[index];
  }

  double _calculateSimilarity(String s1, String s2) {
    // Simple word-based similarity calculation
    final words1 = s1.split(' ').toSet();
    final words2 = s2.split(' ').toSet();
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    if (union.isEmpty) return 0;
    return intersection.length / union.length;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
