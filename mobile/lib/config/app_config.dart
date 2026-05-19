enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.gitSha = '',
  });

  final AppEnvironment environment;
  final Uri apiBaseUrl;

  /// Short SHA of the commit the build was produced from, injected via
  /// `--dart-define=GIT_SHA=...` by `mobile/tool/compute_version.sh`. Empty
  /// string for unstamped `flutter run` development builds.
  final String gitSha;

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
    const gitSha = String.fromEnvironment('GIT_SHA', defaultValue: '');

    return AppConfig(
      environment: _parseEnv(env),
      apiBaseUrl: Uri.parse(apiBaseUrl),
      gitSha: gitSha,
    );
  }
}

