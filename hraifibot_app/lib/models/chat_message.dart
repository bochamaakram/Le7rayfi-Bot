enum MessageSender { user, bot }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final bool isLocal;
  final String? artisanId;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? timestamp,
    this.isLocal = false,
    this.artisanId,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isBot => sender == MessageSender.bot;
}
