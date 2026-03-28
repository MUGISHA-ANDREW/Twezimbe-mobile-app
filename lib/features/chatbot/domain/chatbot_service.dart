import 'package:twezimbeapp/core/data/app_data_repository.dart';

class ChatbotService {
  static const String outOfScopeResponse =
      'Sorry l am unable to provide that information. Contact your admin for more information';

  String getResponse(String input) {
    final query = _normalize(input);
    if (query.isEmpty) {
      return outOfScopeResponse;
    }

    for (final faq in AppDataRepository.faqs) {
      final question = _normalize(faq.question);
      if (question == query ||
          query.contains(question) ||
          question.contains(query)) {
        return faq.answer;
      }
    }

    return outOfScopeResponse;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
