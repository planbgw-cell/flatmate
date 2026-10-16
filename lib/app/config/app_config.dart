/// 앱 전역 환경/API 설정.
enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    this.useMockApi = true,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String appName;

  /// `true` → Mock repositories / `false` → Dio FastAPI repositories.
  /// Override: `--dart-define=USE_MOCK_API=false`
  final bool useMockApi;

  bool get isDev => environment == AppEnvironment.development;

  static const development = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://localhost:8000/api/v1',
    appName: 'Flatmate',
    useMockApi: true,
  );

  static const staging = AppConfig(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://staging-api.flatmate.app/api/v1',
    appName: 'Flatmate',
    useMockApi: false,
  );

  static const production = AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://api.flatmate.app/api/v1',
    appName: 'Flatmate',
    useMockApi: false,
  );

  /// Build-time switches:
  /// - `--dart-define=ENV=prod`
  /// - `--dart-define=USE_MOCK_API=false`
  static AppConfig resolve() {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    const mockDefine = String.fromEnvironment('USE_MOCK_API', defaultValue: '');
    final base = switch (env) {
      'prod' || 'production' => production,
      'staging' => staging,
      _ => development,
    };
    if (mockDefine.isEmpty) return base;
    final useMock = mockDefine.toLowerCase() != 'false';
    return AppConfig(
      environment: base.environment,
      apiBaseUrl: base.apiBaseUrl,
      appName: base.appName,
      useMockApi: useMock,
    );
  }
}
