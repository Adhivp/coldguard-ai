class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    return 'http://10.91.51.23:8000';
  }

  // Scan endpoint
  static const String scan = '/scan/';

  // Timeout configurations (in milliseconds)
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
