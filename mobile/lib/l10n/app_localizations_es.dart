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
  String get housingPlanSummaryMonthlyTotal => 'Total mensual';

  @override
  String housingPlanLoadError(String error) {
    return 'No se pudieron cargar los datos del plan.\n$error';
  }

  @override
  String get housingPlanStepParticipants => 'Participantes';

  @override
  String get housingPlanStepPlanDates => 'Fechas del plan';

  @override
  String get housingPlanStepExpenseCategories => 'Categorías de gastos';

  @override
  String get housingPlanStepExpenses => 'Gastos';

  @override
  String get housingPlanStepSplit => 'Reparto';

  @override
  String get housingPlanStepAgreementRules => 'Reglas del acuerdo';

  @override
  String get housingAgreementRulesIntro =>
      'Activa o desactiva cada regla. Las reglas fijas siguen listadas aunque estén desactivadas para dejar claro qué se negoció. Puedes añadir reglas y quitarlas mientras no haya una propuesta aceptada.';

  @override
  String get housingAgreementRuleCurfewTitle =>
      'Calendario de horas de silencio';

  @override
  String get housingAgreementRuleCurfewPlaceholder =>
      'Semana orientativa (sin fechas): elige la letra del día y usa la cuadrícula. En edición, toca una celda de 30 minutos para alternar sin regla → silencio absoluto (rojo) → silencio moderado (amarillo).';

  @override
  String get housingQuietHoursAbsolute => 'Silencio absoluto';

  @override
  String get housingQuietHoursModerate => 'Silencio moderado';

  @override
  String get housingQuietHoursNoneThisDay => 'Sin horario';

  @override
  String get housingAgreementRuleEarlyWithdrawalTitle => 'Retirada anticipada';

  @override
  String get housingAgreementRuleBuildingTitle =>
      'Normas del edificio / vivienda';

  @override
  String get housingAgreementRuleBuildingHint =>
      'Sugerencias que puedes copiar o adaptar:\n• No fumadores\n• Sin mascotas\n• Nada en los pasillos\n• …';

  @override
  String get housingAgreementRuleEdit => 'Editar';

  @override
  String get housingAgreementRuleFinishEditing => 'Terminar edición';

  @override
  String get housingAgreementRuleTitleRequired =>
      'Escribe un título para esta regla.';

  @override
  String get housingAgreementSuggestionLabel => 'Sugerencia';

  @override
  String get housingAgreementSuggestionCleanlinessTitle =>
      'Limpieza de zonas comunes';

  @override
  String get housingAgreementSuggestionCleanlinessBody =>
      '• Guarda la ropa solo en los espacios asignados.\n• Limpia ducha e inodoro tras usar.\n• Seca la encimera tras cocinar.\n• …';

  @override
  String get housingAgreementSuggestionFridgeTitle => 'Gestión del frigorífico';

  @override
  String get housingAgreementSuggestionFridgeBody =>
      '• Etiqueta lo que no compartes.\n• Tira lo caducado con regularidad.\n• Mantén baldas y puerta limpias.\n• …';

  @override
  String get housingAgreementRuleRemove => 'Quitar regla';

  @override
  String get housingAgreementRuleDismissSuggestion => 'Quitar de la lista';

  @override
  String get housingAgreementRuleAdd => 'Añadir regla';

  @override
  String get housingAgreementRuleAddTitle => 'Añadir regla al acuerdo';

  @override
  String get housingAgreementRuleCustomTitleLabel => 'Título';

  @override
  String get housingAgreementRuleCustomBodyLabel => 'Detalles (opcional)';

  @override
  String get housingAgreementRulesRemovalLockedHint =>
      'Las reglas incluidas en una propuesta aceptada no se pueden quitar; aún puedes desactivarlas.';

  @override
  String get housingAgreementRuleEarlyWithdrawalDisabledHint =>
      'Activa la regla para indicar preaviso y penalización.';

  @override
  String housingPlanParticipantsCount(int count) {
    return '$count participantes';
  }

  @override
  String get housingPlanFewerParticipantsTooltip => 'Menos participantes';

  @override
  String get housingPlanMoreParticipantsTooltip => 'Más participantes';

  @override
  String get housingPlanAddCategoryTooltip => 'Añadir categoría de gasto';

  @override
  String get housingPlanAddExpenseTooltip => 'Añadir gasto';

  @override
  String get housingPlanBack => 'Atrás';

  @override
  String get housingPlanNext => 'Siguiente';

  @override
  String get housingPlanFinish => 'Finalizar';

  @override
  String get housingPlanExpenseValidationMessage =>
      'Añade al menos un gasto. Cada uno necesita un importe válido (fijo o rango mín/máx) y los recurrentes requieren un día del mes.';

  @override
  String get housingPlanSplitValidationMessage =>
      'Cada gasto o categoría debe sumar el 100 % entre los participantes.';

  @override
  String housingPlanCouldNotContinue(String error) {
    return 'No se pudo continuar: $error';
  }

  @override
  String get housingPlanInviteComingSoon =>
      'Invitar a los participantes (próximamente)';

  @override
  String get housingPlanPreviousPerson => 'Persona anterior';

  @override
  String get housingPlanNextPerson => 'Persona siguiente';

  @override
  String get housingPlanParticipantNameLabel => 'Nombre';

  @override
  String get housingPlanParticipantsPlaceholderNote =>
      'Los nombres y avatares son provisionales hasta que alguien se una de verdad.';

  @override
  String get housingPlanYou => 'Tú';

  @override
  String housingPlanCoParticipantUnnamed(int index) {
    return 'Co-participante $index';
  }

  @override
  String get housingPlanPlanStart => 'Inicio del plan';

  @override
  String get housingPlanPlanEnd => 'Fin del plan';

  @override
  String get housingPlanEndDateError =>
      'La fecha de fin debe ser posterior a la de inicio (al menos un día calendario).';

  @override
  String get housingPlanCategoriesEmptyHint =>
      'Pulsa + para añadir una categoría. En el siguiente paso podrás asignar cada gasto a una categoría para mantener juntos los conceptos relacionados.';

  @override
  String get housingPlanDeleteCategoryTitle => 'Eliminar categoría';

  @override
  String get housingPlanDeleteCategoryBody =>
      'Los gastos de esta categoría dejarán de estar asignados a ella. No se eliminan los gastos.';

  @override
  String get housingPlanCancel => 'Cancelar';

  @override
  String get housingPlanDelete => 'Eliminar';

  @override
  String get housingPlanTapToAddExpense => 'Pulsa + para añadir un gasto.';

  @override
  String get housingPlanAddExpensesFirst => 'Añade gastos primero.';

  @override
  String get housingPlanSplitNoCategory => 'Sin categoría';

  @override
  String get housingPlanWithdrawalIntro => 'Reglas de retirada anticipada.';

  @override
  String get housingPlanWithdrawalSameForAll =>
      'Misma regla para todos los participantes';

  @override
  String get housingPlanMinimumNoticeDays => 'Preaviso mínimo (días)';

  @override
  String get housingPlanPenaltyAmount => 'Importe de la penalización';

  @override
  String get housingPlanSummaryMissingAgreement => 'Falta el acuerdo';

  @override
  String get housingPlanSummaryEditPlan => 'Editar plan';

  @override
  String get housingPlanSummaryInvite => 'Invitar a mis participantes';

  @override
  String get housingPlanSummaryDestroy => 'Eliminar plan';

  @override
  String get housingPlanDestroyTitle => 'Eliminar plan';

  @override
  String get housingPlanDestroyBody =>
      'Esto elimina en este dispositivo este plan de vivienda, los gastos, las ratios, el acuerdo y los participantes borrador.';

  @override
  String get housingPlanDestroyConfirm => 'Eliminar';

  @override
  String get housingPlanRemovedSnackbar => 'Plan eliminado';

  @override
  String get housingPlanAddCategoryTitle => 'Añadir categoría';

  @override
  String get housingPlanEditCategoryTitle => 'Editar categoría';

  @override
  String get housingPlanCategoryNameLabel => 'Nombre de la categoría';

  @override
  String get housingPlanCategoryDescriptionLabel =>
      'Qué debe incluir esta categoría (opcional)';

  @override
  String get housingPlanSave => 'Guardar';

  @override
  String get housingPlanAddExpenseTitle => 'Añadir gasto';

  @override
  String get housingPlanEditExpenseTitle => 'Editar gasto';

  @override
  String get housingPlanRecurringSwitch => 'Recurrente';

  @override
  String get housingPlanApproximateAmountSwitch => 'Importe aproximado';

  @override
  String get housingPlanExpenseTitleLabel => 'Título';

  @override
  String get housingPlanCategoryOptionalLabel => 'Categoría (opcional)';

  @override
  String get housingPlanCategoryNone => 'Ninguna';

  @override
  String get housingPlanExpenseDescriptionLabel => 'Descripción (opcional)';

  @override
  String get housingPlanDayOfMonthLabel => 'Día del mes';

  @override
  String get housingPlanMinLabel => 'Mín';

  @override
  String get housingPlanMaxLabel => 'Máx';

  @override
  String get housingPlanAmountLabel => 'Importe';

  @override
  String housingPlanDurationMonthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String housingPlanDurationDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get homeCarSharingPlan => 'Plan de coche';

  @override
  String get homePlaceholderBody =>
      'Esta es una pantalla de inicio provisional para el contenedor MVP publicable.';
}
