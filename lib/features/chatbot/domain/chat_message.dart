import 'chat_action.dart';

enum MessageRole { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final ChatAction? action;
  final List<String>? suggestions;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.action,
    this.suggestions,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.bot(
    String text, {
    ChatAction? action,
    List<String>? suggestions,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.bot,
      timestamp: DateTime.now(),
      action: action,
      suggestions: suggestions,
    );
  }
}
