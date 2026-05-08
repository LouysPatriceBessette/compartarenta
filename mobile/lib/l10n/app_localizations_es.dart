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
  String get onboardingLanguageTitle => 'Idioma';

  @override
  String get onboardingLanguageBody =>
      'Elige el idioma de la aplicación. Puedes cambiarlo en cualquier momento en Ajustes.';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido';

  @override
  String get onboardingWelcomeCopyShort =>
      'Gracias por probar Compartarenta.\n\nLa aplicación es gratis mientras no se use de forma efectiva. Durante esta fase, puedes configurar tu plan de reparto de gastos con todo el detalle que necesites. Este plan servirá como propuesta de acuerdo para compartir con una o más personas.\n\nUna vez que tu plan sea aceptado y se ponga en servicio, comienza la prueba gratuita de 6 semanas.';

  @override
  String get onboardingReadLater => 'Leer más tarde';

  @override
  String get onboardingWelcomeMoreTitle => 'Sobre la prueba y la licencia';

  @override
  String get onboardingWelcomeCopyLong =>
      'Al finalizar la prueba, tú y tus socios podéis continuar comprando una licencia de 4 \$ por persona. Cada participante del plan debe tener una licencia.\n\nEsta licencia financia el desarrollo y el mantenimiento. NUNCA habrá anuncios en la aplicación.\n\nTus datos no se usan de ninguna forma: permanecen en tu dispositivo (y en los dispositivos de los participantes) y en ningún otro lugar. Los datos te pertenecen.\n\nSi no renuevas la licencia, no podrás añadir datos nuevos, pero podrás exportar los datos existentes.';

  @override
  String get onboardingOk => 'OK';

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
  String get prefsCurrencySearchHint => 'Buscar por código o nombre';

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
  String get homeHousingPlan => 'Plan de vivienda';

  @override
  String get homeCarSharingPlan => 'Plan de coche';

  @override
  String get homePlaceholderBody =>
      'Esta es una pantalla de inicio provisional para el contenedor MVP publicable.';
}
