import 'chat_action.dart';

class ChatIntent {
  final String id;
  final List<String> keywords;
  final List<String> phrases;
  final String? route;
  final String response;
  final ChatActionType actionType;
  final List<String>? suggestions;

  const ChatIntent({
    required this.id,
    required this.keywords,
    required this.phrases,
    this.route,
    required this.response,
    this.actionType = ChatActionType.navigate,
    this.suggestions,
  });
}
