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
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonPaste => 'Coller';

  @override
  String get commonBlock => 'Bloquer';

  @override
  String get commonUnblock => 'Débloquer';

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
  String get homeHousingPlan => 'Plan logement';

  @override
  String get homeModuleContacts => 'Contacts';

  @override
  String get homeModuleHousing => 'Logement';

  @override
  String get homeModulePersonalBudget => 'Budget personnel';

  @override
  String get homeModuleVehicle => 'Véhicule';

  @override
  String get homeModuleVehicleSharing => 'Partage de véhicule';

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
  String get housingPlanStepAgreementRules => 'Règles de l\'accord';

  @override
  String get housingAgreementRulesIntro =>
      'Activez ou désactivez chaque règle. Les règles fixes restent visibles même désactivées pour montrer ce qui a été négocié. Vous pouvez ajouter des règles et les retirer tant qu\'aucune proposition n\'a été acceptée.';

  @override
  String get housingAgreementRuleCurfewTitle => 'Calendrier de couvre-feu';

  @override
  String get housingAgreementRuleCurfewPlaceholder =>
      'Semaine indicative (sans dates) : choisissez un jour, puis la grille. En édition, touchez une case de 30 minutes pour faire défiler aucune règle → calme absolu (rouge) → calme modéré (jaune).';

  @override
  String get housingQuietHoursAbsolute => 'Calme absolu';

  @override
  String get housingQuietHoursModerate => 'Calme modéré';

  @override
  String get housingQuietHoursNoneThisDay => 'Aucun horaire';

  @override
  String get housingAgreementRuleEarlyWithdrawalTitle => 'Retrait anticipé';

  @override
  String get housingAgreementRuleBuildingTitle =>
      'Règles de l\'immeuble / du logement';

  @override
  String get housingAgreementRuleBuildingHint =>
      'Exemples à adapter :\n• Logement non-fumeur\n• Pas d\'animaux\n• Rien dans les couloirs\n• …';

  @override
  String get housingAgreementRuleEdit => 'Modifier';

  @override
  String get housingAgreementRuleFinishEditing => 'Terminer l\'édition';

  @override
  String get housingAgreementRuleTitleRequired =>
      'Saisissez un titre pour cette règle.';

  @override
  String get housingAgreementSuggestionLabel => 'Suggestion';

  @override
  String get housingAgreementSuggestionCleanlinessTitle =>
      'Propreté des espaces communs';

  @override
  String get housingAgreementSuggestionCleanlinessBody =>
      '• Gardez vos vêtements aux emplacements prévus.\n• Nettoyez douche et toilettes après usage.\n• Essuyez le plan de travail après cuisine.\n• …';

  @override
  String get housingAgreementSuggestionFridgeTitle =>
      'Gestion du réfrigérateur';

  @override
  String get housingAgreementSuggestionFridgeBody =>
      '• Identifiez clairement ce que vous ne partagez pas.\n• Jetez régulièrement ce qui n\'est plus bon.\n• Gardez tablettes et portes propres.\n• …';

  @override
  String get housingAgreementRuleRemove => 'Retirer la règle';

  @override
  String get housingAgreementRuleDismissSuggestion => 'Retirer de la liste';

  @override
  String get housingAgreementRuleAdd => 'Ajouter une règle';

  @override
  String get housingAgreementRuleAddTitle => 'Ajouter une règle à l\'accord';

  @override
  String get housingAgreementRuleCustomTitleLabel => 'Titre';

  @override
  String get housingAgreementRuleCustomBodyLabel => 'Détails (optionnel)';

  @override
  String get housingAgreementRulesRemovalLockedHint =>
      'Les règles ayant fait partie d\'une proposition acceptée ne peuvent pas être retirées ; vous pouvez encore les désactiver.';

  @override
  String get housingAgreementRuleEarlyWithdrawalDisabledHint =>
      'Activez la règle pour renseigner préavis et pénalité.';

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
  String get housingPlanPreviousPerson => 'Précédent';

  @override
  String get housingPlanNextPerson => 'Suivant';

  @override
  String get housingPlanParticipantNameLabel => 'Nom';

  @override
  String get housingPlanChooseContactAction => 'Choisir un contact';

  @override
  String get housingPlanChangeContactAction => 'Changer de contact';

  @override
  String get housingPlanContactRequired =>
      'Choisissez un contact pour chaque participant avant de continuer.';

  @override
  String get housingPlanParticipantsMustBeConnected =>
      'Chaque co-participant doit être un contact connecté (il utilise l’app avec son propre compte). Invitez-le depuis Contacts d’abord, puis sélectionnez-le ici.';

  @override
  String get housingPlanParticipantsPlaceholderNote =>
      'Les co-participants doivent être des contacts connectés. Le plan conserve une copie du nom et de l’avatar pour garder l’historique lisible.';

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
  String get housingInviteProposalAppBarTitle => 'Proposition d\'invitation';

  @override
  String get housingInviteProposalIntroTitle =>
      'Voici la proposition qui sera envoyée à chacun de vos participants.';

  @override
  String get housingInviteParticipantsSectionTitle => 'Participants';

  @override
  String get housingInviteExpensesSectionTitle => 'Dépenses et répartition';

  @override
  String get housingInviteRulesSectionTitle => 'Règles de l\'accord';

  @override
  String get housingInviteStatusAccepted => 'Accepté';

  @override
  String get housingInviteStatusPending => 'En attente';

  @override
  String get housingInviteStatusNegotiating => 'En négociation';

  @override
  String get housingInviteStatusRejected => 'Rejeté';

  @override
  String get housingInviteAcceptFull => 'J\'accepte en totalité';

  @override
  String get housingInviteNegotiate => 'J\'aimerais négocier';

  @override
  String get housingInviteRejectBlock => 'Je refuse en bloc';

  @override
  String get housingInviteNegotiateMessageLabel =>
      'Message à envoyer avec la demande de négociation';

  @override
  String get housingInviteProposalLockedHint =>
      'Un autre participant est en négociation ou a rejeté cette proposition. Les réponses sont suspendues jusqu\'à révision du plan.';

  @override
  String get housingInviteGenerateCodes => 'Générer les codes d\'invitation';

  @override
  String get housingInviteCodesDialogTitle => 'Codes d\'invitation';

  @override
  String get housingInviteCodesDialogBody =>
      'Chaque code est destiné à un co-participant. Partagez-les comme vous voulez ; l\'enregistrement sur le serveur relais sera ajouté ultérieurement.';

  @override
  String get housingInviteCodesCopyAll => 'Tout copier';

  @override
  String get housingInviteCodesCopied => 'Copié dans le presse-papiers';

  @override
  String get housingInviteRuleOffHint =>
      'Cette règle est désactivée pour cette proposition.';

  @override
  String get housingInviteWithdrawalPerParticipantIntro =>
      'Préavis et pénalité varient selon le participant (voir ci-dessous).';

  @override
  String get housingInviteHousingAgreementTitle => 'Entente de logement';

  @override
  String get housingInviteDateRangeSeparator => ' au ';

  @override
  String get housingInviteSunburstCenterLabel => 'Globalement';

  @override
  String housingInviteSunburstCenterParticipation(String pct) {
    return 'Participation globale $pct%';
  }

  @override
  String get housingInviteSunburstEmptyHint =>
      'Aucune donnée de dépense à afficher pour ce plan.';

  @override
  String housingInviteSunburstLegendAgreementShare(String name, String pct) {
    return '$name - $pct % de l\'entente';
  }

  @override
  String housingInviteSunburstLegendYouParticipation(
    String userAmount,
    String totalAmount,
    String pct,
  ) {
    return 'Votre participation : $userAmount/$totalAmount ($pct %)';
  }

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
  String get carSharingPlanTitle => 'Plan partage de voiture';

  @override
  String get carSharingPlanFinish => 'Terminer';

  @override
  String carSharingOwnerPrompt(String name) {
    return '$name : indiquez s’il s’agit de votre véhicule ou d’une location.';
  }

  @override
  String get carSharingStepVehicle => 'Le véhicule';

  @override
  String get carSharingStepOwner => 'Le propriétaire';

  @override
  String get carSharingStepParticipants => 'Participants';

  @override
  String get carSharingStepInsurance => 'Assurances et immatriculations';

  @override
  String get carSharingStepCurrentState => 'État actuel';

  @override
  String get carSharingStepMaintenance => 'Entretiens à faire';

  @override
  String get carSharingStepAvailability => 'Disponibilités offertes';

  @override
  String get carSharingStepFuel => 'Gestion de l’essence';

  @override
  String get carSharingStepClauses => 'Autres clauses';

  @override
  String get carSharingFieldMake => 'Marque';

  @override
  String get carSharingFieldModel => 'Modèle';

  @override
  String get carSharingFieldColor => 'Couleur';

  @override
  String get carSharingFieldYear => 'Année';

  @override
  String get carSharingOwnerIsOwner => 'Véhicule en propriété';

  @override
  String get carSharingOwnerIsRental => 'Véhicule de location';

  @override
  String get carSharingRentalSharePermission =>
      'Droit de partage obtenu de la part du locateur';

  @override
  String get carSharingRentalContractCopy =>
      'Fournira une copie du contrat de location lors de l’acceptation de l’entente';

  @override
  String get carSharingInsuranceNotify =>
      'Informera les assureurs lors de l’acceptation de l’entente';

  @override
  String get carSharingInsuranceAssumeIncrease =>
      'Assumera l’éventuelle augmentation du prix d’assurance (si non et qu’il y a une augmentation, ce contrat est sujet à renégociation)';

  @override
  String get carSharingInsuranceProvideDocs =>
      'Fournira une copie des papiers d’assurance et d’immatriculation lors de l’acceptation de l’entente';

  @override
  String get carSharingEstimatedValueLabel => 'Valeur estimée';

  @override
  String get carSharingPhotoFront => 'Photo avant — chemin (optionnel)';

  @override
  String get carSharingPhotoLeft => 'Photo côté gauche — chemin (optionnel)';

  @override
  String get carSharingPhotoRight => 'Photo côté droit — chemin (optionnel)';

  @override
  String get carSharingPhotoRear => 'Photo arrière — chemin (optionnel)';

  @override
  String get carSharingPhotoSeatsFront =>
      'Photo sièges avant — chemin (optionnel)';

  @override
  String get carSharingPhotoSeatsRear =>
      'Photo sièges arrière — chemin (optionnel)';

  @override
  String get carSharingPhotoDashboard =>
      'Photo tableau de bord — chemin (optionnel)';

  @override
  String get carSharingPhotoOdometer =>
      'Photo kilométrage — chemin (optionnel)';

  @override
  String get carSharingMaintenanceIntro =>
      'Comme pour les dépenses du plan logement ; elles compteront dans la catégorie « entretien ».';

  @override
  String get carSharingMaintenanceAdd => 'Ajouter un entretien';

  @override
  String get carSharingMaintenanceEditTitle => 'Modifier l’entretien';

  @override
  String get carSharingMaintenanceEmpty =>
      'Aucun entretien prévu pour l’instant.';

  @override
  String get carSharingMaintenanceTitleLabel => 'Titre';

  @override
  String get carSharingMaintenanceAmountLabel => 'Montant';

  @override
  String get carSharingAvailabilityIntro =>
      'Comme la grille du couvre-feu : indiquez les plages où le véhicule est offert aux co-participants. Le reste du temps, il reste à l’usage du propriétaire.';

  @override
  String get carSharingAvailabilityAvailable => 'Offert aux co-participants';

  @override
  String get carSharingAvailabilityOwner => 'Usage propriétaire';

  @override
  String get carSharingFuelIntro =>
      'En mode suivi dans l’app, chaque achat enregistre : date/heure, coût total, volume de carburant, relevé d’odomètre, et s’il s’agit d’un plein. Les pleins servent d’ancrage pour la consommation entre ravitaillements. L’odomètre sert aussi à la distance par utilisation.';

  @override
  String get carSharingFuelUseAppTracking =>
      'Utiliser le suivi essence et odomètre de l’app';

  @override
  String get carSharingFuelCustomHint =>
      'Décrivez un autre mode (non géré par l’app)';

  @override
  String get carSharingClausesIntro =>
      'Clauses facultatives et suggestions. Les règles propres au logement (couvre-feu, retrait anticipé, immeuble) ne figurent pas ici.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsPickerTitle => 'Choisir un contact';

  @override
  String get contactsPickerEmptyTitle =>
      'Aucun contact sélectionnable pour l’instant';

  @override
  String get contactsPickerEmptyBody =>
      'Invitez des personnes et terminez la connexion dans Contacts d’abord. Seuls les contacts connectés peuvent rejoindre ce module.';

  @override
  String get contactsEmptyTitle => 'Aucun contact pour l’instant';

  @override
  String get contactsEmptyBody =>
      'Invitez quelqu’un et connectez-vous via le relais. Les contacts connectés sont réutilisables entre modules.';

  @override
  String get contactsAddContactAction => 'Inviter quelqu’un';

  @override
  String get contactsAddLocalOnlyAction => 'Ajouter un contact local';

  @override
  String get contactsAddLocalOnlyTitle => 'Nouveau contact';

  @override
  String get contactsEditTitle => 'Modifier le contact';

  @override
  String get contactsDetailTitle => 'Contact';

  @override
  String get contactsDetailMissing => 'Ce contact n’existe plus.';

  @override
  String get contactsInviteAction => 'Inviter un contact';

  @override
  String get contactsInviteTitle => 'Inviter un contact';

  @override
  String get contactsInviteIntroTitle => 'Partager un code à usage unique';

  @override
  String get contactsInviteIntroBody =>
      'Générez un code à usage unique et partagez-le en dehors de l’app (SMS, courriel, en personne). La personne qui reçoit le code peut demander à se connecter avec vous. Vous confirmerez avant qu’elle soit ajoutée.';

  @override
  String get contactsInviteValidityLabel => 'Code valide pour';

  @override
  String get contactsInviteGenerateAction => 'Générer le code';

  @override
  String get contactsInviteShareWarning =>
      'Partagez ce code avec une seule personne. Il expire automatiquement et ne fonctionne plus après usage ou révocation.';

  @override
  String get contactsInviteQrLabel =>
      'Scannez ce code QR depuis l’autre appareil, ou utilisez le code texte ci-dessous.';

  @override
  String get contactsInviteQrSemantics => 'Code QR d’invitation';

  @override
  String get contactsInviteShortCodeLabel => 'Code';

  @override
  String get contactsInviteCopyDeepLink => 'Copier le lien';

  @override
  String get contactsInviteCopyShareText => 'Copier l’invitation';

  @override
  String contactsInviteShareText(String link, String code) {
    return 'Vous êtes invité à vous connecter sur Compartarenta.\n\nCode à usage unique :\n$code\n\nPour l’utiliser : ouvrez l’app Compartarenta, allez dans Contacts, touchez l’icône scanner/saisir un code dans le haut de l’écran et collez ce code. Depuis l’appareil où l’app est installée vous pouvez aussi ouvrir : $link';
  }

  @override
  String contactsInviteExpiresAt(String when) {
    return 'Expire $when';
  }

  @override
  String get contactsInviteRevokeAction => 'Révoquer';

  @override
  String get contactsInvitationsTitle => 'Invitations envoyées';

  @override
  String get contactsInvitationsEmpty =>
      'Aucune invitation envoyée pour l’instant.';

  @override
  String contactsInvitationsItemTitle(String createdAt) {
    return 'Invitation · $createdAt';
  }

  @override
  String get contactsInvitationsStatusPending => 'En attente';

  @override
  String get contactsInvitationsStatusUsed => 'Utilisé';

  @override
  String get contactsInvitationsStatusExpired => 'Expiré';

  @override
  String get contactsInvitationsStatusRevoked => 'Révoqué';

  @override
  String get contactsEnterInviteCodeTitle => 'Saisir un code';

  @override
  String get contactsEnterInviteCodeIntro =>
      'Collez ou tapez le code reçu d’un contact. L’app vérifie d’abord son format localement.';

  @override
  String get contactsEnterInviteCodeFieldLabel => 'Code d’invitation';

  @override
  String get contactsEnterInviteCodeScanQr => 'Scanner le code QR';

  @override
  String get contactsEnterInviteCodeScanQrHint =>
      'Pointez la caméra vers un code QR d’invitation Compartarenta.';

  @override
  String get contactsEnterInviteCodeSubmit => 'Se connecter';

  @override
  String get contactsEnterInviteCodeWaveBNote =>
      'La poignée de main chiffrée avec le relais sera activée une fois l’infrastructure du relais déployée.';

  @override
  String get contactsEnterInviteCodeValid => 'Le format du code est valide';

  @override
  String contactsEnterInviteCodeInvitationId(String id) {
    return 'Identifiant d’invitation : $id';
  }

  @override
  String get contactsHandshakeNotAvailableYet =>
      'La poignée de main du relais n’est pas encore disponible. Le code est valide localement, mais il ne peut pas être utilisé tant que le relais n’est pas en ligne.';

  @override
  String get contactsHandshakeDispatching => 'Envoi de la requête au relais…';

  @override
  String get contactsHandshakeDispatched =>
      'Requête envoyée. En attente de la confirmation de l’hôte.';

  @override
  String get contactsHandshakeCompleted =>
      'Connecté. Le contact a été ajouté à votre liste.';

  @override
  String get contactsHandshakeRejected =>
      'Votre interlocuteur a refusé la connexion. Demandez-lui une nouvelle invitation si besoin.';

  @override
  String get contactsHandshakeFailed =>
      'La tentative de connexion a échoué. Vous pouvez réessayer avec une nouvelle invitation.';

  @override
  String get contactsHandshakeErrorRelayUnavailable =>
      'Relais injoignable. Vérifiez votre connexion et réessayez.';

  @override
  String get contactsHandshakeErrorAlreadyCompleted =>
      'Ce code a déjà été utilisé.';

  @override
  String get contactsHandshakeErrorNonceConsumed =>
      'Cette invitation a déjà été honorée.';

  @override
  String get contactsHandshakeErrorExpired => 'Cette invitation a expiré.';

  @override
  String get contactsHandshakeErrorUnknown =>
      'Une erreur est survenue lors de la communication avec le relais.';

  @override
  String get contactsIncomingTitle => 'Demandes de connexion';

  @override
  String get contactsIncomingEmpty => 'Aucune demande de connexion en attente.';

  @override
  String contactsIncomingBody(String name) {
    return '$name souhaite se connecter.';
  }

  @override
  String get contactsIncomingAccept => 'Accepter';

  @override
  String get contactsIncomingReject => 'Refuser';

  @override
  String get contactsIncomingBannerOne => '1 nouvelle demande de connexion';

  @override
  String contactsIncomingBannerMany(int count) {
    return '$count nouvelles demandes de connexion';
  }

  @override
  String get contactsCodeErrorEmpty => 'Saisissez un code pour continuer.';

  @override
  String get contactsCodeErrorTooShort => 'Ce code est trop court.';

  @override
  String get contactsCodeErrorTooLong => 'Ce code est trop long.';

  @override
  String get contactsCodeErrorInvalidCharacters =>
      'Ce code contient des caractères non autorisés.';

  @override
  String get contactsCodeErrorBadChecksum =>
      'Ce code semble mal recopié. Vérifiez les caractères et réessayez.';

  @override
  String get contactsCodeErrorUnsupportedVersion =>
      'Ce code a été créé par une version plus récente de l’app.';

  @override
  String get contactsKindLocalOnly => 'Local uniquement';

  @override
  String get contactsKindDisconnected => 'Déconnecté';

  @override
  String get contactsKindConnected => 'Connecté';

  @override
  String get contactsKindBlocked => 'Bloqué';

  @override
  String get contactsKindDeleted => 'Supprimé';

  @override
  String get contactsFieldNameLabel => 'Nom';

  @override
  String get contactsFieldNameHint =>
      'Tel que cette personne apparaît dans l’app';

  @override
  String get contactsFieldAvatarReadOnlyFootnote =>
      'Seul ce contact peut changer son avatar sur son appareil.';

  @override
  String get contactsFieldAvatarLabel => 'Avatar';

  @override
  String get contactsFieldNotesLabel => 'Notes';

  @override
  String get contactsFieldNotesHint => 'Rappel personnel, non partagé';

  @override
  String get contactsDeleteTitle => 'Supprimer ce contact ?';

  @override
  String get contactsDeleteBody =>
      'Les entrées existantes (logement ou véhicule) qui réfèrent à ce contact conserveront le nom et l\'avatar enregistrés au moment de leur création. Pour travailler à nouveau avec cette personne, créez un nouveau contact local ou envoyez-lui une nouvelle invitation.';

  @override
  String get contactsDeletePreservesHistory =>
      'Les entrées existantes qui réfèrent à ce contact conservent leur nom et avatar.';

  @override
  String get contactsDeleteBlockedByPlansTitle =>
      'Impossible de supprimer ce contact';

  @override
  String contactsDeleteBlockedByPlansBody(int count, String plans) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plans',
      one: 'un plan',
    );
    return 'Ce contact est encore listé comme participant dans $_temp0 : $plans. Retirez-le d\'abord de ces plans, puis vous pourrez supprimer le contact.';
  }

  @override
  String get contactsDeleteBlockedConnectedTitle =>
      'Utilisez Se déconnecter d\'abord';

  @override
  String get contactsDeleteBlockedConnectedBody =>
      'Ce contact est actuellement connecté. Le supprimer sur cet appareil seulement laisserait l\'autre personne penser que la connexion est toujours active. Utilisez d\'abord « Se déconnecter » : un signal de déconnexion chiffré est envoyé au correspondant via le relais et le contact repasse en « local uniquement » sur cet appareil. Vous pourrez ensuite le supprimer normalement.';

  @override
  String get contactsDeleteBlockedConnectedAction => 'Se déconnecter d\'abord';

  @override
  String get contactsBlockTitle => 'Bloquer ce contact ?';

  @override
  String get contactsBlockBody =>
      'Les messages entrants de ce contact seront ignorés localement. Le relais n’est pas informé du blocage.';

  @override
  String get contactsUnblockTitle => 'Débloquer ce contact ?';

  @override
  String get contactsUnblockBody =>
      'Les messages entrants de ce contact seront à nouveau traités.';

  @override
  String get contactsDisconnectAction => 'Se déconnecter';

  @override
  String get contactsDisconnectTitle => 'Se déconnecter de ce contact ?';

  @override
  String get contactsDisconnectBody =>
      'Un avis de déconnexion sera envoyé au relais. Les deux côtés repasseront à des contacts locaux uniquement.';

  @override
  String get contactsDisconnectSent =>
      'Avis de déconnexion envoyé. Le contact est maintenant local uniquement.';

  @override
  String get contactsReconnectAction => 'Demander une reconnexion';

  @override
  String get contactsLabelEditorTitle => 'Comment vous voyez ce contact';

  @override
  String get contactsLabelEditorHint =>
      'Laisser vide pour utiliser le nom qu’il choisit sur son appareil';

  @override
  String get contactsFieldTheirNameLabel => 'Son nom';

  @override
  String get settingsProfileIdentityTitle => 'Votre profil';

  @override
  String get settingsProfileIdentitySubtitle =>
      'Nom et avatar visibles par vos contacts';

  @override
  String get settingsProfileAppearancesTitle =>
      'Comment les autres vous nomment';

  @override
  String get settingsProfileAppearancesBody =>
      'Chaque contact connecté peut partager le nom qu\'il vous donne dans sa liste. Cela transite uniquement dans les mises à jour de profil chiffrées.';

  @override
  String get settingsProfileAppearancesColumnPeer => 'Contact';

  @override
  String get settingsProfileAppearancesColumnTheirLabel =>
      'Son libellé pour vous';

  @override
  String get settingsProfileAppearancesEmpty =>
      'Aucun contact connecté pour l\'instant. Associez-vous à quelqu\'un pour voir ici comment il vous nomme.';

  @override
  String get settingsProfileAppearancesNoSharedLabels =>
      'Aucun contact ne vous a encore communiqué un nom personnalisé dans sa liste.';

  @override
  String get peerNameConflictTitle => 'Le contact a changé de nom';

  @override
  String peerNameConflictBody(String label, String canonical) {
    return 'Vous affichez ce contact sous « $label ». Il utilise maintenant « $canonical » sur son appareil.';
  }

  @override
  String get peerNameConflictUseTheirs => 'Utiliser son nom';

  @override
  String get peerNameConflictKeepMine => 'Garder mon libellé';
}
