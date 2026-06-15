import 'package:flutter/material.dart';

import '../housing/expense_form/expense_amount_parse.dart';

/// Formats user-entered decimal text after blur (never during input).
///
/// [fractionDigits] must be 1 or 2. Returns null when [text] is empty or not
/// a number.
String? formatFixedDecimalInputOnBlur(
  String text, {
  required int fractionDigits,
  bool signed = false,
}) {
  assert(fractionDigits == 1 || fractionDigits == 2);
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  if (fractionDigits == 2) {
    if (signed) {
      final normalized = trimmed.replaceAll(',', '.');
      final negative = normalized.startsWith('-');
      final unsigned = negative ? normalized.substring(1).trim() : normalized;
      if (unsigned.isEmpty) return null;
      final minor = parseAmountMinorFromText(unsigned);
      if (minor == null) return null;
      final formatted = minorToAmountText(minor);
      return negative ? '-$formatted' : formatted;
    }
    final minor = parseAmountMinorFromText(trimmed);
    if (minor == null) return null;
    return minorToAmountText(minor);
  }

  final normalized = trimmed.replaceAll('%', '').replaceAll(',', '.').trim();
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null) return null;
  final scaled = (value * 10).round() / 10;
  return scaled.toStringAsFixed(1);
}

/// Pads missing fractional digits in [controller] on blur only.
void applyFixedDecimalInputOnBlur(
  TextEditingController controller, {
  required int fractionDigits,
  bool signed = false,
  String? emptyBlurText,
}) {
  final trimmed = controller.text.trim();
  if (trimmed.isEmpty) {
    if (emptyBlurText != null && controller.text != emptyBlurText) {
      controller.text = emptyBlurText;
    }
    return;
  }
  final formatted = formatFixedDecimalInputOnBlur(
    controller.text,
    fractionDigits: fractionDigits,
    signed: signed,
  );
  if (formatted != null && controller.text != formatted) {
    controller.text = formatted;
  }
}
