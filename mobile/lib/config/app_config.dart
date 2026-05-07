enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
  });

  final AppEnvironment environment;
  final Uri apiBaseUrl;

  static AppEnvironment _parseEnv(String value) {
    switch (value.trim().toLowerCase()) {
      case 'dev':
        return AppEnvironment.dev;
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }

  static AppConfig fromDartDefines() {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    const apiBaseUrl =
        String.fromEnvironment('API_BASE_URL', defaultValue: 'https://example.invalid');

    return AppConfig(
      environment: _parseEnv(env),
      apiBaseUrl: Uri.parse(apiBaseUrl),
    );
  }
}

