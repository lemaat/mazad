class AppConfig {
  AppConfig._();
  static const host = '10.0.2.2';
  static const port = 8000;
  static String get baseUrl => 'http://$host:$port';
  static String get wsBaseUrl => 'ws://$host:$port';
}
