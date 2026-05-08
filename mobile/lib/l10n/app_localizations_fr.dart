// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Compartarenta';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonFinishSetup => 'Terminer la configuration';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonRestart => 'Redémarrer';

  @override
  String get commonComingSoon => 'Bientôt disponible';

  @override
  String get commonNotSet => 'Non défini';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Changer la langue de l’application';

  @override
  String get languageSystem => 'Système';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get settingsProfileTitle => 'Profil';

  @override
  String get settingsCurrencyTitle => 'Devise';

  @override
  String get settingsDateFormatTitle => 'Format de date';

  @override
  String get settingsDistanceUnitTitle => 'Unité de distance';

  @override
  String get settingsPrivacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get settingsAppVersionTitle => 'Version de l’application';

  @override
  String get settingsEnvironmentTitle => 'Environnement';

  @override
  String get settingsApiBaseUrlTitle => 'URL de base API';

  @override
  String get onboardingTitle => 'Configuration';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue';

  @override
  String get onboardingWelcomeCopy =>
      'Merci d’essayer Compartarenta.\\n\\nDans les prochaines étapes, vous configurerez vos plans de partage (logement, voiture, ou les deux) et démarrerez une période d’essai de 6 semaines en mode réel.\\n\\nVos données restent sur votre appareil — l’application ne les collecte pas.\\n\\nSi ces conditions ne vous conviennent pas, vous pouvez désinstaller à tout moment.';

  @override
  String get onboardingPlansTitle => 'Que voulez-vous configurer ?';

  @override
  String get onboardingPlanHousingTitle => 'Logement partagé';

  @override
  String get onboardingPlanHousingSubtitle => 'Loyer et dépenses du logement.';

  @override
  String get onboardingPlanCarSharingTitle => 'Voiture partagée';

  @override
  String get onboardingPlanCarSharingSubtitle =>
      'Suivi d’utilisation, essence, entretiens, infractions et réservations.';

  @override
  String get onboardingProfileTitle => 'Votre profil';

  @override
  String get onboardingNameLabel => 'Nom';

  @override
  String get onboardingNameHint => 'Nom affiché';

  @override
  String get onboardingAvatarTitle => 'Choisissez un avatar';

  @override
  String get onboardingPreferencesTitle => 'Préférences';

  @override
  String get prefsCurrencyLabel => 'Devise';

  @override
  String get prefsDateFormatLabel => 'Format de date';

  @override
  String get prefsDistanceUnitLabel => 'Unité de distance';

  @override
  String get prefsDistanceUnitKm => 'Kilomètres (km)';

  @override
  String get prefsDistanceUnitMiles => 'Miles';

  @override
  String get prefsTimeZoneLabel => 'Fuseau horaire';

  @override
  String get prefsTimeZoneDevice => 'Utiliser l’heure locale de l’appareil';

  @override
  String get prefsTimeZoneExplicit => 'Choisir un fuseau horaire (plus tard)';

  @override
  String get errorSomethingWentWrongTitle => 'Une erreur est survenue';

  @override
  String get errorSomethingWentWrongBody =>
      'Veuillez réessayer. Si le problème persiste, contactez le support.';

  @override
  String get errorUnknownOnboardingStep => 'Étape de configuration inconnue.';

  @override
  String homeEnvironment(String env) {
    return 'Environnement : $env';
  }

  @override
  String homeApiBaseUrl(String url) {
    return 'URL de base API : $url';
  }

  @override
  String get homePlaceholderBody =>
      'Ceci est un écran d’accueil provisoire pour la coque MVP publiable en boutique.';
}
