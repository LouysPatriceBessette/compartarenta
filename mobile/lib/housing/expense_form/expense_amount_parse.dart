int? parseAmountMinorFromText(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null) return null;
  return (v * 100).round();
}

String minorToAmountText(int? minor) {
  if (minor == null) return '';
  return (minor / 100).toStringAsFixed(2);
}
