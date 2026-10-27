enum ChatActionType { navigate, answer, suggest, ask, none }

class ChatAction {
  final ChatActionType type;
  final String? route;

  const ChatAction({required this.type, this.route});
}
