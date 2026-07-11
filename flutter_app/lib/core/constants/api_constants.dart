class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    return 'http://coldguard-ai.onrender.com';
  }

  // Scan endpoint
  static const String scan = '/scan/';

  // Timeout configurations (in milliseconds)
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
