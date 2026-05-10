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
  String get housingPlanSummaryMonthlyTotal => 'Total mensuel';

  @override
  String housingPlanLoadError(String error) {
    return 'Impossible de charger les données du plan.\n$error';
  }

  @override
  String get housingPlanStepParticipants => 'Participants';

  @override
  String get housingPlanStepPlanDates => 'Dates du plan';

  @override
  String get housingPlanStepExpenseCategories => 'Catégories de dépenses';

  @override
  String get housingPlanStepExpenses => 'Dépenses';

  @override
  String get housingPlanStepSplit => 'Répartition';

  @override
  String get housingPlanStepWithdrawal => 'Retrait anticipé';

  @override
  String housingPlanParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String get housingPlanFewerParticipantsTooltip => 'Moins de participants';

  @override
  String get housingPlanMoreParticipantsTooltip => 'Plus de participants';

  @override
  String get housingPlanAddCategoryTooltip =>
      'Ajouter une catégorie de dépense';

  @override
  String get housingPlanAddExpenseTooltip => 'Ajouter une dépense';

  @override
  String get housingPlanBack => 'Retour';

  @override
  String get housingPlanNext => 'Suivant';

  @override
  String get housingPlanFinish => 'Terminer';

  @override
  String get housingPlanExpenseValidationMessage =>
      'Ajoutez au moins une dépense. Chacune doit avoir un montant valide (fixe ou fourchette min/max) et les dépenses récurrentes nécessitent un jour du mois.';

  @override
  String get housingPlanSplitValidationMessage =>
      'Chaque dépense ou catégorie doit totaliser 100 % entre les participants.';

  @override
  String housingPlanCouldNotContinue(String error) {
    return 'Impossible de continuer : $error';
  }

  @override
  String get housingPlanInviteComingSoon =>
      'Inviter les participants (bientôt)';

  @override
  String get housingPlanPreviousPerson => 'Personne précédente';

  @override
  String get housingPlanNextPerson => 'Personne suivante';

  @override
  String get housingPlanParticipantNameLabel => 'Nom';

  @override
  String get housingPlanParticipantsPlaceholderNote =>
      'Les noms et avatars sont provisoires jusqu’à ce que quelqu’un rejoigne pour de vrai.';

  @override
  String get housingPlanYou => 'Vous';

  @override
  String housingPlanCoParticipantUnnamed(int index) {
    return 'Co-participant $index';
  }

  @override
  String get housingPlanPlanStart => 'Début du plan';

  @override
  String get housingPlanPlanEnd => 'Fin du plan';

  @override
  String get housingPlanEndDateError =>
      'La date de fin doit être après la date de début (d’au moins un jour calendaire).';

  @override
  String get housingPlanCategoriesEmptyHint =>
      'Appuyez sur + pour ajouter une catégorie. À l’étape suivante, vous pourrez rattacher chaque dépense à une catégorie pour garder les postes liés ensemble.';

  @override
  String get housingPlanDeleteCategoryTitle => 'Supprimer la catégorie';

  @override
  String get housingPlanDeleteCategoryBody =>
      'Les dépenses de cette catégorie n’y seront plus rattachées. Les dépenses elles-mêmes ne sont pas supprimées.';

  @override
  String get housingPlanCancel => 'Annuler';

  @override
  String get housingPlanDelete => 'Supprimer';

  @override
  String get housingPlanTapToAddExpense =>
      'Appuyez sur + pour ajouter une dépense.';

  @override
  String get housingPlanAddExpensesFirst => 'Ajoutez d’abord des dépenses.';

  @override
  String get housingPlanSplitNoCategory => 'Sans catégorie';

  @override
  String get housingPlanWithdrawalIntro => 'Règles de retrait anticipé.';

  @override
  String get housingPlanWithdrawalSameForAll =>
      'Même règle pour tous les participants';

  @override
  String get housingPlanMinimumNoticeDays => 'Préavis minimum (jours)';

  @override
  String get housingPlanPenaltyAmount => 'Montant de la pénalité';

  @override
  String get housingPlanSummaryMissingAgreement => 'Accord manquant';

  @override
  String get housingPlanSummaryEditPlan => 'Modifier le plan';

  @override
  String get housingPlanSummaryInvite => 'Inviter mes participants';

  @override
  String get housingPlanSummaryDestroy => 'Supprimer le plan';

  @override
  String get housingPlanDestroyTitle => 'Supprimer le plan';

  @override
  String get housingPlanDestroyBody =>
      'Cela supprime sur cet appareil ce plan logement, les dépenses, les ratios, l’accord et les participants brouillon.';

  @override
  String get housingPlanDestroyConfirm => 'Supprimer';

  @override
  String get housingPlanRemovedSnackbar => 'Plan supprimé';

  @override
  String get housingPlanAddCategoryTitle => 'Ajouter une catégorie';

  @override
  String get housingPlanEditCategoryTitle => 'Modifier la catégorie';

  @override
  String get housingPlanCategoryNameLabel => 'Nom de la catégorie';

  @override
  String get housingPlanCategoryDescriptionLabel =>
      'Que doit contenir cette catégorie (optionnel)';

  @override
  String get housingPlanSave => 'Enregistrer';

  @override
  String get housingPlanAddExpenseTitle => 'Ajouter une dépense';

  @override
  String get housingPlanEditExpenseTitle => 'Modifier la dépense';

  @override
  String get housingPlanRecurringSwitch => 'Récurrent';

  @override
  String get housingPlanApproximateAmountSwitch => 'Montant approximatif';

  @override
  String get housingPlanExpenseTitleLabel => 'Titre';

  @override
  String get housingPlanCategoryOptionalLabel => 'Catégorie (optionnel)';

  @override
  String get housingPlanCategoryNone => 'Aucune';

  @override
  String get housingPlanExpenseDescriptionLabel => 'Description (optionnel)';

  @override
  String get housingPlanDayOfMonthLabel => 'Jour du mois';

  @override
  String get housingPlanMinLabel => 'Min';

  @override
  String get housingPlanMaxLabel => 'Max';

  @override
  String get housingPlanAmountLabel => 'Montant';

  @override
  String housingPlanDurationMonthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '1 mois',
    );
    return '$_temp0';
  }

  @override
  String housingPlanDurationDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get homeCarSharingPlan => 'Plan voiture';

  @override
  String get homePlaceholderBody =>
      'Ceci est un écran d’accueil provisoire pour la coque MVP publiable en boutique.';
}
