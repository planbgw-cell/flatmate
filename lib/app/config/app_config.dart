/// 앱 전역 환경/API 설정.
/// FastAPI 서버 연동 시 [apiBaseUrl]만 환경별로 교체하면 됩니다.
enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String appName;

  bool get isDev => environment == AppEnvironment.development;

  static const development = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://127.0.0.1:8000',
    appName: 'Flatmate',
  );

  static const staging = AppConfig(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://staging-api.flatmate.app',
    appName: 'Flatmate',
  );

  static const production = AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://api.flatmate.app',
    appName: 'Flatmate',
  );

  /// 빌드 시 `--dart-define=ENV=prod` 로 전환.
  static AppConfig resolve() {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    return switch (env) {
      'prod' || 'production' => production,
      'staging' => staging,
      _ => development,
    };
  }
}
