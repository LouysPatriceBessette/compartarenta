import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// ~2–3 character inset for agreement rule prose (not centered off hints).
const EdgeInsetsDirectional agreementRuleBodyPadding = EdgeInsetsDirectional.only(
  start: 8,
);

/// Strips list markers users should not be prompted to add manually.
String agreementRuleBodyPlain(String body) {
  return body
      .split('\n')
      .map((line) {
        var t = line.trimLeft();
        if (t.startsWith('• ')) return t.substring(2).trim();
        if (t.startsWith('· ')) return t.substring(2).trim();
        if (t.startsWith('- ')) return t.substring(2).trim();
        return line.trim();
      })
      .where((line) => line.isNotEmpty)
      .join('\n');
}

/// True when [text] is still the install-time building-rules example hint
/// (with or without legacy list bullets).
bool isAgreementBuildingRulesExampleText(String text, String hint) {
  final plainText = agreementRuleBodyPlain(text);
  if (plainText.isEmpty) return false;
  return plainText == agreementRuleBodyPlain(hint);
}

String agreementRuleEnabledStatusLabel(AppLocalizations l10n, bool enabled) =>
    enabled
        ? l10n.housingAgreementRuleStatusEnabled
        : l10n.housingAgreementRuleStatusDisabled;

/// Status line above the rule title on amendment rule cards.
Widget agreementRuleCardTitleColumn({
  required BuildContext context,
  required AppLocalizations l10n,
  required bool enabled,
  required String title,
  TextStyle? titleStyle,
}) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        agreementRuleEnabledStatusLabel(l10n, enabled),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: titleStyle ?? theme.textTheme.titleMedium,
      ),
    ],
  );
}

Widget agreementRuleOffHint(BuildContext context, String text) {
  return Align(
    alignment: Alignment.center,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

Widget agreementRuleBodyText(
  BuildContext context,
  String text, {
  TextStyle? style,
}) {
  final theme = Theme.of(context);
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: Padding(
      padding: agreementRuleBodyPadding,
      child: Text(
        agreementRuleBodyPlain(text),
        textAlign: TextAlign.start,
        style: style ?? theme.textTheme.bodyMedium,
      ),
    ),
  );
}
