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
      "Thank you for contacting Twezimbe, reach out to the system admin on toll free 08004002774";

  String getResponse(String input) {
    final query = _normalize(input);

    // Empty input -> default greeting
    if (query.isEmpty) {
      return _defaultGreetingResponse;
    }

    // If the user greets the bot, return a greeting response.
    for (final entry in _greetings.entries) {
      if (query == entry.key || query.startsWith(entry.key) || query.contains(entry.key)) {
        return _getRandomResponse(entry.value);
      }
    }

    final faqResponse = _matchFaq(query);
    if (faqResponse != null) {
      return faqResponse;
    }


    // For any other input, return the fixed admin contact message per requirement.
    return _outOfScopeResponse;
  }

  String _getRandomResponse(List<String> responses) {
    final index = DateTime.now().millisecondsSinceEpoch % responses.length;
    return responses[index];
  }

  String? _matchFaq(String query) {
    for (final faq in AppDataRepository.faqs) {
      final question = _normalize(faq.question);

      if (query == question || query.contains(question) || question.contains(query)) {
        return faq.answer;
      }

      if (_calculateSimilarity(query, question) > 0.45) {
        return faq.answer;
      }
    }

    return null;
  }

  double _calculateSimilarity(String s1, String s2) {
    final words1 = s1.split(' ').where((word) => word.isNotEmpty).toSet();
    final words2 = s2.split(' ').where((word) => word.isNotEmpty).toSet();
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
