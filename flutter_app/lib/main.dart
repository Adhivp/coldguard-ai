import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:code_card_ai/app.dart';
import 'package:code_card_ai/core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize on-device AI engine
  await FlutterGemma.initialize();

  // Initialize dependency injection locator
  await di.init();

  runApp(const App());
}
