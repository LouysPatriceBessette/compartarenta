import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'expense_plan_line_view_data.dart';
import 'expense_split_grid.dart';
import 'expense_split_grid_logic.dart';
import 'like_ratio_selector.dart';
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
  }) : readOnly = false,
       viewData = null;

  const ExpensePlanLineFormBody.presentation({
    super.key,
    required ExpensePlanLineViewData this.viewData,
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
       splitRevision = null;

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
        _readOnlyField(
          context,
          label: l10n.housingExpenseNameLabel,
          value: title!,
        )
      else
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: l10n.housingExpenseNameLabel,
          ),
          onChanged: (_) => onTitleChanged?.call(),
        ),
      const SizedBox(height: 8),
      if (readOnly)
        _readOnlyField(
          context,
          label: l10n.housingPlanExpenseDescriptionLabel,
          value: description!.isEmpty ? '—' : description,
          maxLines: 4,
        )
      else
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: l10n.housingPlanExpenseDescriptionLabel,
          ),
          maxLines: 4,
          minLines: 2,
        ),
      if (readOnly)
        _readOnlySwitchRow(
          context,
          title: l10n.housingPlanRecurringSwitch,
          value: recurring,
          subtitle: recurring ? recurSummary : null,
        )
      else ...[
        SwitchListTile(
          title: Text(l10n.housingPlanRecurringSwitch),
          value: isRecurring,
          onChanged: onRecurringChanged,
        ),
        if (isRecurring)
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(l10n.housingExpenseRecurrenceTapToSet),
            subtitle: recurrenceSummary == null
                ? null
                : Text(recurrenceSummary!),
            onTap: onRecurrenceTap,
          ),
      ],
      const SizedBox(height: 8),
      if (readOnly)
        _readOnlyField(
          context,
          label: l10n.housingPlanAmountLabel,
          value: amountText!.isEmpty ? '—' : amountText,
        )
      else
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            budgetCap
                ? l10n.housingExpenseAmountBudgetMax
                : l10n.housingExpenseAmountDetermined,
            style: theme.textTheme.bodyLarge,
          ),
        )
      else
        _ExpenseAmountTypeSelector(
          amountIsBudgetCap: amountIsBudgetCap,
          determinedLabel: l10n.housingExpenseAmountDetermined,
          budgetLabel: l10n.housingExpenseAmountBudgetMax,
          onChanged: onAmountTypeChanged!,
        ),
      if (readOnly)
        _readOnlyField(
          context,
          label: l10n.housingExpensePaymentResponsibleLabel,
          value: paymentLabel!,
        )
      else
        _PaymentResponsibleField(
          value: paymentResponsibleId,
          label: l10n.housingExpensePaymentResponsibleLabel,
          allLabel: l10n.housingExpensePaymentResponsibleAll,
          participantIds: participantIds,
          participantNames: participantNames,
          onChanged: onPaymentResponsibleChanged!,
        ),
      if (splitRevision != null)
        ListenableBuilder(
          listenable: splitRevision!,
          builder: (context, _) => _buildSplitSection(
            context,
            l10n,
            theme,
            splitState: currentSplitState?.call(),
            currency: currency,
            selectedTemplateId: selectedTemplateId,
          ),
        )
      else
        _buildSplitSection(
          context,
          l10n,
          theme,
          splitState: readOnly ? data!.split : currentSplitState?.call(),
          currency: currency,
          selectedTemplateId: selectedTemplateId,
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
        if (!readOnly)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: splitState == null ? null : onEqualParts,
              child: Text(l10n.housingExpenseEqualParts),
            ),
          ),
        if (!readOnly && templates.isNotEmpty) ...[
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
                  onChanged: onSplitChanged!,
                  onRowAmountChanged: onRowAmountChanged!,
                  onRowPercentChanged: onRowPercentChanged!,
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
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Icon(
        value ? Icons.check_circle_outline : Icons.remove_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Owns dropdown state so parent [setState] on amount does not reset the field.
class _PaymentResponsibleField extends StatefulWidget {
  const _PaymentResponsibleField({
    required this.value,
    required this.label,
    required this.allLabel,
    required this.participantIds,
    required this.participantNames,
    required this.onChanged,
  });

  final String? value;
  final String label;
  final String allLabel;
  final List<String> participantIds;
  final List<String> participantNames;
  final ValueChanged<String?> onChanged;

  @override
  State<_PaymentResponsibleField> createState() => _PaymentResponsibleFieldState();
}

class _PaymentResponsibleFieldState extends State<_PaymentResponsibleField> {
  late String? _selected = widget.value;

  @override
  void didUpdateWidget(covariant _PaymentResponsibleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _selected = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: _selected,
      decoration: InputDecoration(labelText: widget.label),
      items: [
        DropdownMenuItem(value: null, child: Text(widget.allLabel)),
        for (var i = 0; i < widget.participantIds.length; i++)
          DropdownMenuItem(
            value: widget.participantIds[i],
            child: Text(widget.participantNames[i]),
          ),
      ],
      onChanged: (v) {
        setState(() => _selected = v);
        widget.onChanged(v);
      },
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
