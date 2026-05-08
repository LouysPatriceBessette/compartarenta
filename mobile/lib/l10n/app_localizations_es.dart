// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Compartarenta';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonFinishSetup => 'Finalizar configuración';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonRestart => 'Reiniciar';

  @override
  String get commonComingSoon => 'Próximamente';

  @override
  String get commonNotSet => 'No configurado';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Cambiar el idioma de la aplicación';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get settingsProfileTitle => 'Perfil';

  @override
  String get settingsCurrencyTitle => 'Moneda';

  @override
  String get settingsDateFormatTitle => 'Formato de fecha';

  @override
  String get settingsDistanceUnitTitle => 'Unidad de distancia';

  @override
  String get settingsPrivacyPolicyTitle => 'Política de privacidad';

  @override
  String get settingsAppVersionTitle => 'Versión de la aplicación';

  @override
  String get settingsEnvironmentTitle => 'Entorno';

  @override
  String get settingsApiBaseUrlTitle => 'URL base de la API';

  @override
  String get onboardingTitle => 'Configuración';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido';

  @override
  String get onboardingWelcomeCopy =>
      'Gracias por probar Compartarenta.\\n\\nEn los próximos pasos, configurarás tus planes de reparto (vivienda compartida, coche compartido o ambos) y comenzarás una prueba de 6 semanas en modo real.\\n\\nTus datos se quedan en tu dispositivo: esta aplicación no los recopila.\\n\\nSi estas condiciones no te funcionan, puedes desinstalar en cualquier momento.';

  @override
  String get onboardingPlansTitle => '¿Qué quieres configurar?';

  @override
  String get onboardingPlanHousingTitle => 'Vivienda compartida';

  @override
  String get onboardingPlanHousingSubtitle => 'Alquiler y gastos del hogar.';

  @override
  String get onboardingPlanCarSharingTitle => 'Coche compartido';

  @override
  String get onboardingPlanCarSharingSubtitle =>
      'Uso, combustible, mantenimiento, infracciones y reservas.';

  @override
  String get onboardingProfileTitle => 'Tu perfil';

  @override
  String get onboardingNameLabel => 'Nombre';

  @override
  String get onboardingNameHint => 'Nombre para mostrar';

  @override
  String get onboardingAvatarTitle => 'Elige un avatar';

  @override
  String get onboardingPreferencesTitle => 'Preferencias';

  @override
  String get prefsCurrencyLabel => 'Moneda';

  @override
  String get prefsDateFormatLabel => 'Formato de fecha';

  @override
  String get prefsDistanceUnitLabel => 'Unidad de distancia';

  @override
  String get prefsDistanceUnitKm => 'Kilómetros (km)';

  @override
  String get prefsDistanceUnitMiles => 'Millas';

  @override
  String get prefsTimeZoneLabel => 'Zona horaria';

  @override
  String get prefsTimeZoneDevice => 'Usar hora local del dispositivo';

  @override
  String get prefsTimeZoneExplicit => 'Elegir una zona horaria (más tarde)';

  @override
  String get errorSomethingWentWrongTitle => 'Algo salió mal';

  @override
  String get errorSomethingWentWrongBody =>
      'Por favor, inténtalo de nuevo. Si continúa, contacta con soporte.';

  @override
  String get errorUnknownOnboardingStep => 'Paso de configuración desconocido.';

  @override
  String homeEnvironment(String env) {
    return 'Entorno: $env';
  }

  @override
  String homeApiBaseUrl(String url) {
    return 'URL base de la API: $url';
  }

  @override
  String get homePlaceholderBody =>
      'Esta es una pantalla de inicio provisional para el contenedor MVP publicable.';
}
