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
  String get onboardingLanguageTitle => 'Langue';

  @override
  String get onboardingLanguageBody =>
      'Choisissez la langue de l’application. Vous pourrez la changer en tout temps dans les paramètres.';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue';

  @override
  String get onboardingWelcomeCopyShort =>
      'Merci d’essayer Compartarenta.\n\nL’application est gratuite tant qu’elle n’est pas effectivement utilisée. Pendant cette phase, vous pouvez configurer votre plan de partage des dépenses aussi précisément que nécessaire. Ce plan servira de proposition d’accord à partager avec une ou plusieurs personnes.\n\nUne fois votre plan accepté et mis en service, la période d’essai gratuit de six semaines commence.';

  @override
  String get onboardingReadLater => 'Lire plus tard';

  @override
  String get onboardingWelcomeMoreTitle =>
      'À propos de l’essai et de la licence';

  @override
  String get onboardingWelcomeCopyLong =>
      'À l’issue de l’essai, vous et vos partenaires pourrez choisir de continuer en achetant une licence à 4 \$ par personne. Chaque participant au plan doit posséder une licence.\n\nCette licence permet de financer le développement et la maintenance de l’application. Il n’y aura JAMAIS de publicité dans l’application.\n\nVos données ne seront utilisées en aucune façon : elles restent en permanence sur votre appareil (et sur ceux des participants) et nulle part ailleurs. Les données vous appartiennent.\n\nSi vous ne renouvelez pas la licence, vous ne pourrez plus ajouter de nouvelles données, mais vous pourrez exporter celles qui existent.';

  @override
  String get onboardingOk => 'Ok';

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
  String get prefsCurrencySearchHint => 'Rechercher par code ou nom';

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
  String get homeHousingPlan => 'Plan logement';

  @override
  String get homeCarSharingPlan => 'Plan voiture';

  @override
  String get homePlaceholderBody =>
      'Ceci est un écran d’accueil provisoire pour la coque MVP publiable en boutique.';
}
