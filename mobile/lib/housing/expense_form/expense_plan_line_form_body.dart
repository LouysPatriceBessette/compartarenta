import 'package:flutter/material.dart';
import '../../widgets/app_decimal_text_field.dart';
import '../../widgets/app_text_field.dart';

import '../../l10n/app_localizations.dart';
import 'expense_plan_line_view_data.dart';
import 'expense_split_grid.dart';
import 'expense_split_grid_logic.dart';
import 'like_ratio_selector.dart';
import 'plan_participant_dropdown_value.dart';
import '../../db/app_database.dart';

/// Shared expense line layout for edit and read-only presentation.
class ExpensePlanLineFormBody extends StatelessWidget {
  const ExpensePlanLineFormBody.edit({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.amountController,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.recurrenceSummary,
    required this.onRecurrenceTap,
    required this.onTitleChanged,
    required this.onAmountChanged,
    required this.amountIsBudgetCap,
    required this.onAmountTypeChanged,
    required this.paymentResponsibleId,
    required this.participantIds,
    required this.participantNames,
    required this.onPaymentResponsibleChanged,
    required this.currentSplitState,
    required this.currencyCode,
    required this.onEqualParts,
    required this.templates,
    required this.selectedTemplateId,
    required this.onLikeSelected,
    required this.onSplitChanged,
    required this.onRowAmountChanged,
    required this.onRowPercentChanged,
    required this.splitRevision,
    this.lockRecurrenceAndSplit = false,
  }) : readOnly = false,
       viewData = null,
       highlightPredicate = null,
       highlightColor = null;

  const ExpensePlanLineFormBody.presentation({
    super.key,
    required ExpensePlanLineViewData this.viewData,
    this.highlightPredicate,
    this.highlightColor,
  }) : readOnly = true,
       titleController = null,
       descriptionController = null,
       amountController = null,
       isRecurring = false,
       onRecurringChanged = null,
       recurrenceSummary = null,
       onRecurrenceTap = null,
       onTitleChanged = null,
       onAmountChanged = null,
       amountIsBudgetCap = false,
       onAmountTypeChanged = null,
       paymentResponsibleId = null,
       participantIds = const [],
       participantNames = const [],
       onPaymentResponsibleChanged = null,
       currentSplitState = null,
       currencyCode = '',
       onEqualParts = null,
       templates = const [],
       selectedTemplateId = null,
       onLikeSelected = null,
       onSplitChanged = null,
       onRowAmountChanged = null,
       onRowPercentChanged = null,
       splitRevision = null,
       lockRecurrenceAndSplit = false;

  /// When set, wraps read-only fields whose [fieldKey] returns true.
  final bool Function(String fieldKey)? highlightPredicate;
  final Color? highlightColor;

  final bool readOnly;
  final ExpensePlanLineViewData? viewData;

  final TextEditingController? titleController;
  final TextEditingController? descriptionController;
  final TextEditingController? amountController;
  final bool isRecurring;
  final ValueChanged<bool>? onRecurringChanged;
  final String? recurrenceSummary;
  final VoidCallback? onRecurrenceTap;
  final VoidCallback? onTitleChanged;
  final VoidCallback? onAmountChanged;
  final bool amountIsBudgetCap;
  final ValueChanged<bool>? onAmountTypeChanged;
  final String? paymentResponsibleId;
  final List<String> participantIds;
  final List<String> participantNames;
  final ValueChanged<String?>? onPaymentResponsibleChanged;
  final ExpenseSplitGridState? Function()? currentSplitState;
  final String currencyCode;
  final VoidCallback? onEqualParts;
  final List<PlanRatioTemplate> templates;
  final String? selectedTemplateId;
  final ValueChanged<String?>? onLikeSelected;
  final VoidCallback? onSplitChanged;
  final void Function(int index, int amountMinor)? onRowAmountChanged;
  final void Function(int index, int percentTenths)? onRowPercentChanged;
  final Listenable? splitRevision;
  final bool lockRecurrenceAndSplit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = viewData;

    final title = readOnly ? data!.title : null;
    final description = readOnly ? data!.description : null;
    final recurring = readOnly ? data!.isRecurring : isRecurring;
    final recurSummary = readOnly ? data!.recurrenceSummary : recurrenceSummary;
    final amountText = readOnly ? data!.amountText : null;
    final budgetCap = readOnly ? data!.amountIsBudgetCap : amountIsBudgetCap;
    final paymentLabel =
        readOnly ? data!.paymentResponsibleLabel : null;
    final currency = readOnly ? data!.currencyCode : currencyCode;

    final children = <Widget>[
      if (readOnly)
        _highlightWrap(
          'title',
          _readOnlyField(
            context,
            label: l10n.housingExpenseNameLabel,
            value: title!,
          ),
        )
      else
        AppTextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: l10n.housingExpenseNameLabel,
          ),
          onChanged: (_) => onTitleChanged?.call(),
        ),
      const SizedBox(height: 8),
      if (readOnly)
        _highlightWrap(
          'description',
          _readOnlyField(
            context,
            label: l10n.housingPlanExpenseDescriptionLabel,
            value: description!.isEmpty ? '—' : description,
            maxLines: 4,
          ),
        )
      else
        AppTextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: l10n.housingPlanExpenseDescriptionLabel,
          ),
          maxLines: 4,
          minLines: 2,
        ),
      if (readOnly)
        _highlightWrap(
          'recurring',
          _readOnlySwitchRow(
            context,
            title: l10n.housingPlanRecurringSwitch,
            value: recurring,
            subtitle: recurring ? recurSummary : null,
            highlightRecurrence: highlightPredicate?.call('recurrence') ?? false,
            highlightColor: highlightColor,
          ),
        )
      else
        _AmendmentLockedSection(
          locked: lockRecurrenceAndSplit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                title: Text(l10n.housingPlanRecurringSwitch),
                value: isRecurring,
                onChanged: lockRecurrenceAndSplit ? null : onRecurringChanged,
              ),
              if (isRecurring)
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(l10n.housingExpenseRecurrenceTapToSet),
                  subtitle: recurrenceSummary == null
                      ? null
                      : Text(recurrenceSummary!),
                  onTap: lockRecurrenceAndSplit ? null : onRecurrenceTap,
                ),
            ],
          ),
        ),
      const SizedBox(height: 8),
      if (readOnly)
        _highlightWrap(
          'amount',
          _readOnlyField(
            context,
            label: l10n.housingPlanAmountLabel,
            value: amountText!.isEmpty ? '—' : amountText,
          ),
        )
      else
        AppDecimalTextField(
          controller: amountController!,
          fractionDigits: 2,
          decoration: InputDecoration(
            labelText: l10n.housingPlanAmountLabel,
          ),
          onChanged: (_) => onAmountChanged?.call(),
        ),
      const SizedBox(height: 8),
      Text(
        l10n.housingExpenseAmountTypeLabel,
        style: theme.textTheme.titleSmall,
      ),
      if (readOnly)
        _highlightWrap(
          'amountType',
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              budgetCap
                  ? l10n.housingExpenseAmountBudgetMax
                  : l10n.housingExpenseAmountDetermined,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        )
      else
        _ExpenseAmountTypeSelector(
          amountIsBudgetCap: amountIsBudgetCap,
          determinedLabel: l10n.housingExpenseAmountDetermined,
          budgetLabel: l10n.housingExpenseAmountBudgetMax,
          onChanged: onAmountTypeChanged!,
        ),
      if (!readOnly) const SizedBox(height: 24),
      if (readOnly)
        _highlightWrap(
          'payment',
          _readOnlyField(
            context,
            label: l10n.housingExpensePaymentResponsibleLabel,
            value: paymentLabel!,
          ),
        )
      else
        _PaymentResponsibleField(
          theme: theme,
          value: paymentResponsibleId,
          label: l10n.housingExpensePaymentResponsibleLabel,
          allLabel: l10n.housingExpensePaymentResponsibleAll,
          participantIds: participantIds,
          participantNames: participantNames,
          onChanged: onPaymentResponsibleChanged!,
        ),
      _AmendmentLockedSection(
        locked: lockRecurrenceAndSplit,
        child: _highlightWrap(
          'split',
          splitRevision != null
              ? ListenableBuilder(
                  listenable: splitRevision!,
                  builder: (context, _) => _buildSplitSection(
                    context,
                    l10n,
                    theme,
                    splitState: currentSplitState?.call(),
                    currency: currency,
                    selectedTemplateId: selectedTemplateId,
                    interactionsEnabled: !lockRecurrenceAndSplit,
                  ),
                )
              : _buildSplitSection(
                  context,
                  l10n,
                  theme,
                  splitState: readOnly ? data!.split : currentSplitState?.call(),
                  currency: currency,
                  selectedTemplateId: selectedTemplateId,
                  interactionsEnabled: !lockRecurrenceAndSplit,
                ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildSplitSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required ExpenseSplitGridState? splitState,
    required String currency,
    required String? selectedTemplateId,
    bool interactionsEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Text(
          l10n.housingExpenseSplitSectionTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (!readOnly && interactionsEnabled)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: splitState == null ? null : onEqualParts,
              child: Text(l10n.housingExpenseEqualParts),
            ),
          ),
        if (!readOnly && interactionsEnabled && templates.isNotEmpty) ...[
          LikeRatioSelector(
            templates: templates,
            participantIds: participantIds,
            selectedTemplateId: selectedTemplateId,
            onSelected: onLikeSelected!,
          ),
          const SizedBox(height: 8),
        ],
        if (splitState != null)
          readOnly
              ? ExpenseSplitGrid.readOnly(
                  state: splitState,
                  currencyCode: currency,
                )
              : ExpenseSplitGrid(
                  state: splitState,
                  currencyCode: currency,
                  onChanged: interactionsEnabled ? onSplitChanged! : () {},
                  onRowAmountChanged:
                      interactionsEnabled ? onRowAmountChanged! : (_, _) {},
                  onRowPercentChanged:
                      interactionsEnabled ? onRowPercentChanged! : (_, _) {},
                )
        else if (!readOnly)
          SizedBox(
            height: 220,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.housingExpenseEnterAmountForSplit,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _highlightWrap(String fieldKey, Widget child) {
    final predicate = highlightPredicate;
    final color = highlightColor;
    if (predicate == null || color == null || !predicate(fieldKey)) {
      return child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: child,
      ),
    );
  }

  static Widget _readOnlyField(
    BuildContext context, {
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: maxLines,
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  static Widget _readOnlySwitchRow(
    BuildContext context, {
    required String title,
    required bool value,
    required String? subtitle,
    bool highlightRecurrence = false,
    Color? highlightColor,
  }) {
    Widget? subtitleWidget;
    if (subtitle != null) {
      final text = Text(subtitle);
      subtitleWidget = highlightRecurrence && highlightColor != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: text,
              ),
            )
          : text;
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitleWidget,
      trailing: Icon(
        value ? Icons.check_circle_outline : Icons.remove_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _AmendmentLockedSection extends StatelessWidget {
  const _AmendmentLockedSection({
    required this.locked,
    required this.child,
  });

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return AbsorbPointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}

class _PaymentResponsibleField extends StatelessWidget {
  const _PaymentResponsibleField({
    required this.theme,
    required this.value,
    required this.label,
    required this.allLabel,
    required this.participantIds,
    required this.participantNames,
    required this.onChanged,
  });

  final ThemeData theme;
  final String? value;
  final String label;
  final String allLabel;
  final List<String> participantIds;
  final List<String> participantNames;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePlanParticipantDropdownValue(value, participantIds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        DropdownMenu<String?>(
          key: ValueKey<String?>(resolved),
          initialSelection: resolved,
          width: double.infinity,
          menuHeight: 240,
          requestFocusOnTap: true,
          enableFilter: false,
          dropdownMenuEntries: [
            DropdownMenuEntry<String?>(value: null, label: allLabel),
            for (var i = 0; i < participantIds.length; i++)
              DropdownMenuEntry<String?>(
                value: participantIds[i],
                label: participantNames[i],
              ),
          ],
          onSelected: onChanged,
        ),
      ],
    );
  }
}

/// Segmented control avoids [RadioGroup] dispose issues when the parent rebuilds.
class _ExpenseAmountTypeSelector extends StatelessWidget {
  const _ExpenseAmountTypeSelector({
    required this.amountIsBudgetCap,
    required this.determinedLabel,
    required this.budgetLabel,
    required this.onChanged,
  });

  final bool amountIsBudgetCap;
  final String determinedLabel;
  final String budgetLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment<bool>(value: false, label: Text(determinedLabel)),
        ButtonSegment<bool>(value: true, label: Text(budgetLabel)),
      ],
      selected: {amountIsBudgetCap},
      emptySelectionAllowed: false,
      onSelectionChanged: (selected) {
        if (selected.isEmpty) return;
        onChanged(selected.first);
      },
    );
  }
}
