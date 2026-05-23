import 'package:flutter/material.dart';

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
