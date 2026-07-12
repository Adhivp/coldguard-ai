import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/features/scanner/data/datasources/scan_remote_datasource.dart';
import '../../data/models/model_info.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/model_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ModelService modelService;
  InferenceChat? _inferenceChat;
  final List<ChatMessageModel> _messages = [];
  StreamSubscription<double>? _downloadSubscription;

  ChatBloc({required this.modelService}) : super(ChatInitial()) {
    on<ChatLoadCatalog>(_onLoadCatalog);
    on<ChatDownloadModel>(_onDownloadModel);
    on<ChatDeleteModel>(_onDeleteModel);
    on<ChatDownloadProgressUpdate>(_onDownloadProgressUpdate);
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
    final prefs = await SharedPreferences.getInstance();
    final activeModelId = prefs.getString('active_model_id');
    final activeBackendName = prefs.getString('active_model_backend');

    final Map<String, bool> installationStatus = {};
    final Map<String, bool> loadingStates = {};
    final Map<String, PreferredBackend> selectedBackends = {};
    final Map<String, double> downloadProgress = {};

    ModelInfo? activeModel;
    PreferredBackend activeBackend = PreferredBackend.gpu;

    for (final model in ModelCatalog.allModels) {
      final isInstalled = await modelService.isModelInstalled(model);
      installationStatus[model.id] = isInstalled;
      loadingStates[model.id] = false;

      PreferredBackend backend = PreferredBackend.gpu;
      if (activeModelId == model.id && activeBackendName != null) {
        try {
          backend = PreferredBackend.values.firstWhere(
            (e) => e.name == activeBackendName,
          );
        } catch (_) {}
        if (isInstalled) {
          activeModel = model;
          activeBackend = backend;
        }
      }

      selectedBackends[model.id] = backend;
      downloadProgress[model.id] = 0.0;
    }

    if (activeModel != null) {
      // Retry auto-activation up to 3 times — the LiteRT engine may need
      // a moment to initialize on a cold start.
      const maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          debugPrint('[ChatBloc] Auto-activation attempt $attempt/$maxRetries');
          await modelService.activateModel(activeModel, backend: activeBackend);
          _inferenceChat = await modelService.activeModel!.createChat(
            modelType: activeModel.modelType,
            supportImage: activeModel.supportsVision,
            supportAudio: activeModel.supportsAudio,
            supportsFunctionCalls: activeModel.supportsFunctionCalling,
            isThinking: activeModel.supportsThinking,
          );

          try {
            final products = await sl<ScanRemoteDataSource>().getAllProducts();
            final contextPrompt =
                "SYSTEM CONTEXT:\n"
                "You are ColdGuard AI, a precise, helpful, on-device logistics assistant.\n"
                "IMPORTANT: Keep your answers extremely concise, direct, and under 3-4 sentences. Do not use verbose preambles or greetings. Always complete your sentences.\n\n"
                "Here is the real-time supply chain context fetched from the server:\n\n"
                "Active Products:\n"
                "${products.map((p) => '- Product ID: ${p.productId}, Device: ${p.deviceId}, Temp: ${p.latestTemperature}°C, Readings: ${p.totalReadings} points, Last Sync: ${p.latestReadingTs}').join('\n')}\n\n"
                "Please use this data to answer user questions about active products or shipments. "
                "Reply with 'CONTEXT RECEIVED'.";

            await _inferenceChat!.addQuery(
              Message.text(text: contextPrompt, isUser: true),
            );
            await for (final _ in _inferenceChat!.generateChatResponseAsync()) {
              // Warm up
            }
          } catch (contextError) {
            debugPrint(
              '[ChatBloc] Failed to fetch system context: $contextError',
            );
          }

          _messages.clear();
          _messages.add(
            ChatMessageModel(
              text:
                  "Hello! Welcome back to ColdGuard Local AI assistant (${activeModel.name}). Ask me anything about your product.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );

          emit(
            ChatActiveSession(
              activeModel: activeModel,
              activeBackend: activeBackend,
              messages: List.from(_messages),
              isTyping: false,
            ),
          );
          return;
        } catch (e) {
          debugPrint('[ChatBloc] Auto-activation attempt $attempt failed: $e');
          if (attempt < maxRetries) {
            // Wait before retrying — give the engine time to initialize
            await Future.delayed(const Duration(milliseconds: 1500));
          } else {
            // All retries exhausted — clear saved prefs so the catalog shows
            debugPrint('[ChatBloc] All auto-activation retries exhausted');
            await prefs.remove('active_model_id');
            await prefs.remove('active_model_backend');
          }
        }
      }
    }

    emit(
      ChatCatalogReady(
        models: ModelCatalog.allModels,
        installationStatus: installationStatus,
        loadingStates: loadingStates,
        selectedBackends: selectedBackends,
        downloadProgress: downloadProgress,
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

    _downloadSubscription?.cancel();
    _downloadSubscription = modelService.downloadProgress.listen((progress) {
      add(
        ChatDownloadProgressUpdate(modelId: event.model.id, progress: progress),
      );
    });

    try {
      await modelService.installModel(event.model);
      _downloadSubscription?.cancel();
      final isInstalled = await modelService.isModelInstalled(event.model);

      final updatedStatus = Map<String, bool>.from(
        currentReadyState.installationStatus,
      );
      updatedStatus[event.model.id] = isInstalled;
      updatedLoadings[event.model.id] = false;

      final updatedProgress = Map<String, double>.from(
        currentReadyState.downloadProgress,
      );
      updatedProgress[event.model.id] = 0.0;

      emit(
        currentReadyState.copyWith(
          installationStatus: updatedStatus,
          loadingStates: updatedLoadings,
          downloadProgress: updatedProgress,
        ),
      );
    } catch (e) {
      _downloadSubscription?.cancel();
      updatedLoadings[event.model.id] = false;

      final updatedProgress = Map<String, double>.from(
        currentReadyState.downloadProgress,
      );
      updatedProgress[event.model.id] = 0.0;

      emit(
        currentReadyState.copyWith(
          loadingStates: updatedLoadings,
          downloadProgress: updatedProgress,
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

      try {
        final products = await sl<ScanRemoteDataSource>().getAllProducts();

        final contextPrompt =
            "SYSTEM CONTEXT:\n"
            "You are ColdGuard AI, a precise, helpful, on-device logistics assistant.\n"
            "IMPORTANT: Keep your answers extremely concise, direct, and under 3-4 sentences. Do not use verbose preambles or greetings. Always complete your sentences.\n\n"
            "Here is the real-time supply chain context fetched from the server:\n\n"
            "Active Products:\n"
            "${products.map((p) => '- Product ID: ${p.productId}, Device: ${p.deviceId}, Temp: ${p.latestTemperature}°C, Readings: ${p.totalReadings} points, Last Sync: ${p.latestReadingTs}').join('\n')}\n\n"
            "Please use this data to answer user questions about active products or shipments. "
            "Reply with 'CONTEXT RECEIVED'.";

        await _inferenceChat!.addQuery(
          Message.text(text: contextPrompt, isUser: true),
        );
        await for (final _ in _inferenceChat!.generateChatResponseAsync()) {
          // Warm up local LLM memory with context
        }
      } catch (contextError) {
        debugPrint('[ChatBloc] Failed to fetch system context: $contextError');
      }

      _messages.clear();
      _messages.add(
        ChatMessageModel(
          text:
              "Hello! I am your ColdGuard AI assistant (${event.model.name}). Ask me anything about your product.",
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

      String processedMessage = event.message;
      try {
        final productMatch = RegExp(
          r'\bPROD-\w+\b',
          caseSensitive: false,
        ).firstMatch(event.message);
        if (productMatch != null) {
          final productId = productMatch.group(0)!.toUpperCase();
          final detail = await sl<ScanRemoteDataSource>().scanProduct(
            productId,
          );
          processedMessage =
              "REAL-TIME API DATA for $productId:\n"
              "- Product Name: ${detail.product.name}\n"
              "- Category: ${detail.product.category}\n"
              "- Batch/Device ID: ${detail.product.batchNumber}\n"
              "- Manufacturer: ${detail.product.manufacturer}\n"
              "- Manufactured At: ${detail.product.manufacturedAt}\n"
              "- Storage Requirement: ${detail.product.storageRequirement}\n"
              "- Current Location: ${detail.product.currentLocation}\n"
              "- Latest Temperature: ${detail.current.temperature}°C\n"
              "- Latest Humidity: ${detail.current.humidity}%\n"
              "- Condition Status: ${detail.current.status}\n"
              "- Health Score: ${detail.life.healthScore}%\n"
              "- Excursions Count: ${detail.life.totalExcursions}\n"
              "- Expiry Estimation: ${detail.life.estimatedExpiry}\n\n"
              "USER QUERY: ${event.message}";
        }
      } catch (e) {
        debugPrint('[ChatBloc] Failed to fetch dynamic product context: $e');
      }

      final queryToSend =
          "$processedMessage\n\n(Remember: Be very concise and make sure to finish your response properly.)";
      await _inferenceChat!.addQuery(
        Message.text(text: queryToSend, isUser: true),
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

  void _onResetSelection(
    ChatResetSelection event,
    Emitter<ChatState> emit,
  ) async {
    _inferenceChat = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_model_id');
    await prefs.remove('active_model_backend');
    add(const ChatLoadCatalog());
  }

  void _onDownloadProgressUpdate(
    ChatDownloadProgressUpdate event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatCatalogReady) return;
    final currentReadyState = state as ChatCatalogReady;

    final updatedProgress = Map<String, double>.from(
      currentReadyState.downloadProgress,
    );
    updatedProgress[event.modelId] = event.progress;

    emit(currentReadyState.copyWith(downloadProgress: updatedProgress));
  }

  Future<void> _onDeleteModel(
    ChatDeleteModel event,
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
      await modelService.deleteModel(event.model);

      final updatedStatus = Map<String, bool>.from(
        currentReadyState.installationStatus,
      );
      updatedStatus[event.model.id] = false;
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
          errorMessage: 'Delete failed: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
