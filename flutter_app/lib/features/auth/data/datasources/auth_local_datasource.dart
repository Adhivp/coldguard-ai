import 'package:code_card_ai/core/error/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> getToken();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  // In-memory token storage simulation
  static String? _cachedToken;

  @override
  Future<void> cacheToken(String token) async {
    try {
      _cachedToken = token;
    } catch (e) {
      throw const CacheException('Failed to write authentication token to local storage.');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return _cachedToken;
    } catch (e) {
      throw const CacheException('Failed to read authentication token from local storage.');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      _cachedToken = null;
    } catch (e) {
      throw const CacheException('Failed to clear cache.');
    }
  }
}
