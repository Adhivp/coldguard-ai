import 'package:equatable/equatable.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../data/models/model_info.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadCatalog extends ChatEvent {
  const ChatLoadCatalog();
}

class ChatDownloadModel extends ChatEvent {
  final ModelInfo model;
  const ChatDownloadModel({required this.model});

  @override
  List<Object?> get props => [model];
}

class ChatActivateModel extends ChatEvent {
  final ModelInfo model;
  final PreferredBackend backend;
  const ChatActivateModel({required this.model, required this.backend});

  @override
  List<Object?> get props => [model, backend];
}

class ChatSendMessage extends ChatEvent {
  final String message;
  const ChatSendMessage({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatStopGeneration extends ChatEvent {
  const ChatStopGeneration();
}

class ChatResetSelection extends ChatEvent {
  const ChatResetSelection();
}

class ChatDownloadProgressUpdate extends ChatEvent {
  final String modelId;
  final double progress;
  const ChatDownloadProgressUpdate({required this.modelId, required this.progress});

  @override
  List<Object?> get props => [modelId, progress];
}

class ChatDeleteModel extends ChatEvent {
  final ModelInfo model;
  const ChatDeleteModel({required this.model});

  @override
  List<Object?> get props => [model];
}
