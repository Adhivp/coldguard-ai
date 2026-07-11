import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';

abstract class ScanLocalDataSource {
  Future<void> saveScanResult(ScanResultModel result);
  Future<List<Map<String, dynamic>>> getScanHistory();
  Future<void> clearScanHistory();
}

class ScanLocalDataSourceImpl implements ScanLocalDataSource {
  static const String _keyScanHistory = 'key_scan_history';

  @override
  Future<void> saveScanResult(ScanResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJsonList = prefs.getStringList(_keyScanHistory) ?? [];
    
    // Create map with result and scan timestamp
    final entry = {
      'result': result.toJson(),
      'scanned_at': DateTime.now().toIso8601String(),
    };
    
    // Add to beginning of history list (newest first)
    historyJsonList.insert(0, jsonEncode(entry));
    
    await prefs.setStringList(_keyScanHistory, historyJsonList);
  }

  @override
  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJsonList = prefs.getStringList(_keyScanHistory) ?? [];
    
    return historyJsonList.map((item) {
      return jsonDecode(item) as Map<String, dynamic>;
    }).toList();
  }

  @override
  Future<void> clearScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyScanHistory);
  }
}
