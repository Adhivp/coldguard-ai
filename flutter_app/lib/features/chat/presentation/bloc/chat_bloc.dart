import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../data/models/model_info.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/model_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ModelService modelService;
  InferenceChat? _inferenceChat;
  final List<ChatMessageModel> _messages = [];

  ChatBloc({required this.modelService}) : super(ChatInitial()) {
    on<ChatLoadCatalog>(_onLoadCatalog);
    on<ChatDownloadModel>(_onDownloadModel);
    on<ChatActivateModel>(_onActivateModel);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatStopGeneration>(_onStopGeneration);
    on<ChatResetSelection>(_onResetSelection);
  }

  Future<void> _onLoadCatalog(
    ChatLoadCatalog event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatCatalogLoading());
    final Map<String, bool> installationStatus = {};
    final Map<String, bool> loadingStates = {};
    final Map<String, PreferredBackend> selectedBackends = {};

    for (final model in ModelCatalog.allModels) {
      final isInstalled = await modelService.isModelInstalled(model);
      installationStatus[model.id] = isInstalled;
      loadingStates[model.id] = false;
      selectedBackends[model.id] = PreferredBackend.gpu;
    }

    emit(
      ChatCatalogReady(
        models: ModelCatalog.allModels,
        installationStatus: installationStatus,
        loadingStates: loadingStates,
        selectedBackends: selectedBackends,
      ),
    );
  }

  Future<void> _onDownloadModel(
    ChatDownloadModel event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatCatalogReady) return;
    final currentReadyState = state as ChatCatalogReady;

    final updatedLoadings = Map<String, bool>.from(
      currentReadyState.loadingStates,
    );
    updatedLoadings[event.model.id] = true;

    emit(
      currentReadyState.copyWith(
        loadingStates: updatedLoadings,
        errorMessage: null,
      ),
    );

    try {
      await modelService.installModel(event.model);
      final isInstalled = await modelService.isModelInstalled(event.model);

      final updatedStatus = Map<String, bool>.from(
        currentReadyState.installationStatus,
      );
      updatedStatus[event.model.id] = isInstalled;
      updatedLoadings[event.model.id] = false;

      emit(
        currentReadyState.copyWith(
          installationStatus: updatedStatus,
          loadingStates: updatedLoadings,
        ),
      );
    } catch (e) {
      updatedLoadings[event.model.id] = false;
      emit(
        currentReadyState.copyWith(
          loadingStates: updatedLoadings,
          errorMessage: 'Download failed: $e',
        ),
      );
    }
  }

  Future<void> _onActivateModel(
    ChatActivateModel event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatCatalogReady) {
      final catalogReadyState = state as ChatCatalogReady;
      final updatedLoadings = Map<String, bool>.from(
        catalogReadyState.loadingStates,
      );
      updatedLoadings[event.model.id] = true;
      emit(
        catalogReadyState.copyWith(
          loadingStates: updatedLoadings,
          errorMessage: null,
        ),
      );
    }

    try {
      emit(const ChatModelActivating());
      await modelService.activateModel(event.model, backend: event.backend);

      _inferenceChat = await modelService.activeModel!.createChat(
        modelType: event.model.modelType,
        supportImage: event.model.supportsVision,
        supportAudio: event.model.supportsAudio,
        supportsFunctionCalls: event.model.supportsFunctionCalling,
        isThinking: event.model.supportsThinking,
      );

      _messages.clear();
      _messages.add(
        ChatMessageModel(
          text:
              "Hello! I am your ColdGuard AI assistant (${event.model.name}). Ask me anything about vaccine storage, temperature alerts, or logistics monitoring.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      emit(
        ChatActiveSession(
          activeModel: event.model,
          activeBackend: event.backend,
          messages: List.from(_messages),
          isTyping: false,
        ),
      );
    } catch (e) {
      if (state is ChatCatalogReady) {
        final catalogReadyState = state as ChatCatalogReady;
        final updatedLoadings = Map<String, bool>.from(
          catalogReadyState.loadingStates,
        );
        updatedLoadings[event.model.id] = false;
        emit(
          catalogReadyState.copyWith(
            loadingStates: updatedLoadings,
            errorMessage: 'Activation failed: $e',
          ),
        );
      } else {
        emit(ChatError(message: 'Activation failed: $e'));
      }
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatActiveSession) return;
    final activeState = state as ChatActiveSession;

    final userMessage = ChatMessageModel(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    // Add empty assistant response bubble for streaming
    _messages.add(
      ChatMessageModel(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      ),
    );

    emit(activeState.copyWith(messages: List.from(_messages), isTyping: true));

    try {
      if (_inferenceChat == null) {
        throw Exception("Chat session is not active.");
      }

      await _inferenceChat!.addQuery(
        Message.text(text: event.message, isUser: true),
      );

      final buffer = StringBuffer();
      final thinkingBuffer = StringBuffer();
      bool inThinking = false;

      await emit.forEach<dynamic>(
        _inferenceChat!.generateChatResponseAsync(),
        onData: (response) {
          if (response is TextResponse) {
            if (inThinking) {
              inThinking = false;
            }
            buffer.write(response.token);
          } else if (response is ThinkingResponse) {
            if (!inThinking) {
              inThinking = true;
            }
            thinkingBuffer.write(response.content);
          }

          _messages.last = _messages.last.copyWith(
            text: buffer.toString(),
            reasoning: thinkingBuffer.isNotEmpty
                ? thinkingBuffer.toString()
                : null,
          );

          return activeState.copyWith(
            messages: List.from(_messages),
            isTyping: true,
          );
        },
      );

      _messages.last = _messages.last.copyWith(isStreaming: false);
      emit(
        activeState.copyWith(messages: List.from(_messages), isTyping: false),
      );
    } catch (e) {
      _messages.last = ChatMessageModel(
        text: "Error during local inference: $e",
        isUser: false,
        timestamp: DateTime.now(),
      );
      emit(
        activeState.copyWith(messages: List.from(_messages), isTyping: false),
      );
    }
  }

  void _onStopGeneration(ChatStopGeneration event, Emitter<ChatState> emit) {
    if (state is! ChatActiveSession) return;
    final activeState = state as ChatActiveSession;

    if (_inferenceChat != null) {
      _inferenceChat!.stopGeneration();
      if (_messages.isNotEmpty && _messages.last.isStreaming) {
        _messages.last = _messages.last.copyWith(isStreaming: false);
      }
      emit(
        activeState.copyWith(messages: List.from(_messages), isTyping: false),
      );
    }
  }

  void _onResetSelection(ChatResetSelection event, Emitter<ChatState> emit) {
    _inferenceChat = null;
    add(const ChatLoadCatalog());
  }
}
