class AppConstants {
  AppConstants._();

  static const String appName = 'Market App';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'http://207.180.233.84:8000';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJORFZNQjkiLCJ1c2VyX2lkIjoiTkRWTUI5Iiwicm9sZSI6InF1YW5fbHlfY2hvIiwibG9naW5fbmFtZSI6ImhpZXVxdWFubHkiLCJ1c2VyX25hbWUiOiJUclx1MWVhN24gVlx1MDEwM24gSGlcdTFlYmZ1dXV1dXUiLCJleHAiOjE3NzQwMjQ4NjMsInR5cGUiOiJhY2Nlc3MifQ.I02WdZvYXbewhP_C2hub4Mz3NKBt2E3CqwOUQZePRU0';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';

  // Pagination
  static const int defaultPageSize = 10;
  static const int defaultPage = 1;

  // Image
  static const String defaultAvatar = 'assets/images/default_avatar.png';
  static const String defaultProduct = 'assets/images/default_product.png';

  // Animation Duration
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
