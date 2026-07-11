import 'package:flutter_gemma/flutter_gemma.dart';

/// Represents a downloadable/runnable LLM model in the catalog.
class ModelInfo {
  final String id;
  final String name;
  final String family;
  final String description;
  final String url;
  final double sizeGB;
  final ModelType modelType;
  final ModelFileType fileType;
  final bool supportsVision;
  final bool supportsThinking;
  final bool supportsFunctionCalling;
  final bool supportsAudio;
  final bool needsAuth;
  final int maxTokens;
  final List<String> languages;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.family,
    required this.description,
    required this.url,
    required this.sizeGB,
    required this.modelType,
    required this.fileType,
    this.supportsVision = false,
    this.supportsThinking = false,
    this.supportsFunctionCalling = false,
    this.supportsAudio = false,
    this.needsAuth = false,
    this.maxTokens = 1024,
    this.languages = const ['Multilingual'],
  });

  /// Human-readable size string
  String get sizeLabel {
    if (sizeGB >= 1.0) {
      return '${sizeGB.toStringAsFixed(1)} GB';
    }
    return '${(sizeGB * 1024).toInt()} MB';
  }

  /// The local filename extracted from the URL
  String get filename => url.split('/').last;

  /// Whether this model has any special capabilities
  bool get hasSpecialCapabilities =>
      supportsVision || supportsThinking || supportsFunctionCalling || supportsAudio;
}

/// Complete catalog of supported models.
class ModelCatalog {
  ModelCatalog._();

  static const List<ModelInfo> allModels = [
    // ─── DeepSeek R1 ──────────────────────────────────────────────
    ModelInfo(
      id: 'deepseek_r1',
      name: 'DeepSeek R1',
      family: 'DeepSeek',
      description: 'High-performance reasoning and code generation with thinking mode',
      url: 'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Generic-int4.task',
      sizeGB: 1.7,
      modelType: ModelType.deepSeek,
      fileType: ModelFileType.task,
      supportsThinking: true,
      supportsFunctionCalling: true,
      maxTokens: 2048,
    ),

    // ─── Gemma 4 ──────────────────────────────────────────────────
    ModelInfo(
      id: 'gemma4_e2b',
      name: 'Gemma 4 E2B',
      family: 'Gemma 4',
      description: 'Next-gen multimodal chat — text, image, audio with thinking mode',
      url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
      sizeGB: 2.4,
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
      supportsVision: true,
      supportsThinking: true,
      supportsFunctionCalling: true,
      supportsAudio: true,
      maxTokens: 2048,
    ),

    // ─── Gemma 3 ──────────────────────────────────────────────────
    ModelInfo(
      id: 'gemma3_1b',
      name: 'Gemma 3 1B',
      family: 'Gemma 3',
      description: 'Small, extremely fast balanced text generation',
      url: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
      sizeGB: 0.5,
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
      supportsFunctionCalling: true,
      maxTokens: 1024,
    ),

    // ─── SmolLM ───────────────────────────────────────────────────
    ModelInfo(
      id: 'smollm_135m',
      name: 'SmolLM 135M',
      family: 'SmolLM',
      description: 'Perfect for quick testing, low memory consumption',
      url: 'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/SmolLM-135M-Instruct-int4.task',
      sizeGB: 0.132,
      modelType: ModelType.general,
      fileType: ModelFileType.task,
      maxTokens: 512,
      languages: ['English'],
    ),
  ];

  /// Find model by ID
  static ModelInfo? getById(String id) {
    try {
      return allModels.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
