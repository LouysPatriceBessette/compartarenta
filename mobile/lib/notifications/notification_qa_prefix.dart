/// Temporary QA labels for notification tap testing (see dev-ideas list).
///
/// Remove this file and its call sites after destination QA is complete.
const bool kNotificationQaNumberPrefixEnabled = true;

/// Prepends `# [listNumber]` to [text] when [kNotificationQaNumberPrefixEnabled].
String notificationQaPrefix(int listNumber, String text) {
  if (!kNotificationQaNumberPrefixEnabled) return text;
  return '#$listNumber $text';
}
