import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/model_info.dart';

/// Manages on-device LLM model installation, preferred backends, and activation.
class ModelService {
  ModelService._();
  static final ModelService instance = ModelService._();

  final StreamController<double> _downloadProgressController =
      StreamController<double>.broadcast();
  Stream<double> get downloadProgress => _downloadProgressController.stream;

  String? _activeModelId;
  String? get activeModelId => _activeModelId;

  InferenceModel? _activeModel;
  InferenceModel? get activeModel => _activeModel;

  /// Check if a model file is registered in preferences OR physically sideloaded.
  Future<bool> isModelInstalled(ModelInfo model) async {
    try {
      final filename = model.url.split('/').last;
      final isInstalled = await FlutterGemma.isModelInstalled(filename);
      if (isInstalled) return true;

      // Self-healing: if file exists in app_flutter directory, register it!
      final fileExists = await _checkFileExists(filename);
      if (fileExists) {
        debugPrint('[ModelService] Sideloaded file detected for ${model.name}, registering in repository...');
        await _registerLocalModel(filename, model.url, (model.sizeGB * 1024 * 1024 * 1024).toInt());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[ModelService] Error checking model installation: $e');
      return false;
    }
  }

  Future<bool> _checkFileExists(String filename) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/$filename');
      final exists = await file.exists();
      if (exists) {
        final length = await file.length();
        debugPrint('[ModelService] Local file $filename exists. Size: $length bytes.');
        // We consider the model file valid if it is of non-trivial size (>100MB)
        return length > 100 * 1024 * 1024;
      }
      return false;
    } catch (e) {
      debugPrint('[ModelService] Error checking file existence: $e');
      return false;
    }
  }

  Future<void> _registerLocalModel(String filename, String url, int sizeBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save model metadata matching SharedPreferencesModelRepository schema
      final modelKey = 'model_$filename';
      final modelData = {
        'id': filename,
        'source': {
          'type': 'network',
          'url': url,
        },
        'installedAt': DateTime.now().toIso8601String(),
        'sizeBytes': sizeBytes,
        'type': 'ModelType.inference',
        'hasLoraWeights': false,
      };
      await prefs.setString(modelKey, jsonEncode(modelData));

      // Update gemma index
      const indexKey = 'model_index';
      final indexJson = prefs.getString(indexKey);
      List<String> index = [];
      if (indexJson != null) {
        try {
          index = (jsonDecode(indexJson) as List<dynamic>).cast<String>();
        } catch (_) {}
      }
      if (!index.contains(filename)) {
        index.add(filename);
        await prefs.setString(indexKey, jsonEncode(index));
      }
      debugPrint('[ModelService] Successfully self-healed and registered model: $filename');
    } catch (e) {
      debugPrint('[ModelService] Error registering local model: $e');
    }
  }

  /// Install a model from the web catalog using flutter_gemma's installer.
  Future<void> installModel(
    ModelInfo model, {
    String? authToken,
  }) async {
    debugPrint('[ModelService] Downloading and installing model: ${model.name}');

    final installer = FlutterGemma.installModel(
      modelType: model.modelType,
      fileType: model.fileType,
    );

    if (model.needsAuth && authToken != null) {
      await installer.fromNetwork(model.url, token: authToken).install();
    } else {
      await installer.fromNetwork(model.url).install();
    }

    debugPrint('[ModelService] Model install finished: ${model.name}');
  }

  /// Activate the specified model with the selected hardware backend delegate.
  Future<InferenceModel> activateModel(
    ModelInfo model, {
    PreferredBackend? backend,
  }) async {
    debugPrint('[ModelService] Activating model: ${model.name} with backend: $backend');

    _activeModel = await FlutterGemma.getActiveModel(
      maxTokens: model.maxTokens,
      preferredBackend: backend,
      supportImage: model.supportsVision,
      supportAudio: model.supportsAudio,
    );

    _activeModelId = model.id;

    // Save active model ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_model_id', model.id);

    debugPrint('[ModelService] Active model set successfully: ${model.name}');
    return _activeModel!;
  }

  /// Close model / dispose
  void dispose() {
    _downloadProgressController.close();
  }
}
