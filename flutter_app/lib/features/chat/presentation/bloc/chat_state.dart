import 'package:equatable/equatable.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../data/models/model_info.dart';
import '../../data/models/chat_message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatCatalogLoading extends ChatState {
  const ChatCatalogLoading();
}

class ChatCatalogReady extends ChatState {
  final List<ModelInfo> models;
  final Map<String, bool> installationStatus;
  final Map<String, bool> loadingStates;
  final Map<String, PreferredBackend> selectedBackends;
  final Map<String, double> downloadProgress;
  final String? errorMessage;

  const ChatCatalogReady({
    required this.models,
    required this.installationStatus,
    required this.loadingStates,
    required this.selectedBackends,
    required this.downloadProgress,
    this.errorMessage,
  });

  ChatCatalogReady copyWith({
    List<ModelInfo>? models,
    Map<String, bool>? installationStatus,
    Map<String, bool>? loadingStates,
    Map<String, PreferredBackend>? selectedBackends,
    Map<String, double>? downloadProgress,
    String? errorMessage,
  }) {
    return ChatCatalogReady(
      models: models ?? this.models,
      installationStatus: installationStatus ?? this.installationStatus,
      loadingStates: loadingStates ?? this.loadingStates,
      selectedBackends: selectedBackends ?? this.selectedBackends,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        models,
        installationStatus,
        loadingStates,
        selectedBackends,
        downloadProgress,
        errorMessage,
      ];
}

class ChatModelActivating extends ChatState {
  const ChatModelActivating();
}

class ChatActiveSession extends ChatState {
  final ModelInfo activeModel;
  final PreferredBackend activeBackend;
  final List<ChatMessageModel> messages;
  final bool isTyping;

  const ChatActiveSession({
    required this.activeModel,
    required this.activeBackend,
    required this.messages,
    this.isTyping = false,
  });

  ChatActiveSession copyWith({
    ModelInfo? activeModel,
    PreferredBackend? activeBackend,
    List<ChatMessageModel>? messages,
    bool? isTyping,
  }) {
    return ChatActiveSession(
      activeModel: activeModel ?? this.activeModel,
      activeBackend: activeBackend ?? this.activeBackend,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [activeModel, activeBackend, messages, isTyping];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
