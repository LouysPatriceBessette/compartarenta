enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.entitlementBaseUrl,
    this.gitSha = '',
  });

  final AppEnvironment environment;
  final Uri apiBaseUrl;

  /// Entitlement service base URL. When null, entitlement client calls and
  /// relay `entitlement_gate` metadata are disabled.
  final Uri? entitlementBaseUrl;

  bool get entitlementEnabled =>
      entitlementBaseUrl != null &&
      entitlementBaseUrl!.host != 'example.invalid';

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
    const entitlementBaseUrlRaw =
        String.fromEnvironment('ENTITLEMENT_BASE_URL', defaultValue: '');
    const gitSha = String.fromEnvironment('GIT_SHA', defaultValue: '');

    Uri? entitlementBaseUrl;
    if (entitlementBaseUrlRaw.trim().isNotEmpty) {
      entitlementBaseUrl = Uri.parse(entitlementBaseUrlRaw.trim());
    }

    return AppConfig(
      environment: _parseEnv(env),
      apiBaseUrl: Uri.parse(apiBaseUrl),
      entitlementBaseUrl: entitlementBaseUrl,
      gitSha: gitSha,
    );
  }
}

