class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? reasoning;
  final bool isStreaming;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.reasoning,
    this.isStreaming = false,
  });

  ChatMessageModel copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? reasoning,
    bool? isStreaming,
  }) {
    return ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      reasoning: reasoning ?? this.reasoning,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
