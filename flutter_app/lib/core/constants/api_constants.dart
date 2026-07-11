class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.example.com';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  
  // Timeout configurations (in milliseconds)
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
