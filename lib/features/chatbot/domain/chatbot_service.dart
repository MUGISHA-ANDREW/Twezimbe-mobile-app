class ChatbotService {
  static const String outOfScopeResponse =
      'Sorry l am unable to provide that information. Contact your admin for more information';

  String getResponse(String _) {
    return outOfScopeResponse;
  }
}
