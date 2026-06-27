import 'dart:math';

import 'package:path/path.dart' as p;

import '../../housing/expense_form/expense_amount_parse.dart';
import 'realized_expense_status.dart';

final _tempNameRandom = Random();

/// Temporary proof name while the expense form is being edited.
String temporaryProofFileName({required String extension}) {
  final ext = _normalizeExtension(extension);
  final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final salt = _tempNameRandom.nextInt(0x7fffffff);
  return 'proof-tmp-$stamp-$salt$ext';
}

bool isTemporaryProofFileName(String fileName) {
  return p.basename(fileName).startsWith('proof-tmp-');
}

/// Final proof name at expense submission: `YYYY-MM-DD_HH-MM_<line>_<amount>.<ext>`.
String finalProofFileName({
  required DateTime paymentDate,
  required DateTime submittedAt,
  required String lineTitleLabel,
  required int amountMinor,
  required String extension,
  int collisionSuffix = 0,
}) {
  final ext = _normalizeExtension(extension);
  final datePart = _formatPaymentDate(paymentDate);
  final timePart = _formatSubmissionTime(submittedAt);
  final linePart = slugifyProofLineLabel(lineTitleLabel);
  final amountPart = minorToAmountText(amountMinor);
  final base = '${datePart}_${timePart}_${linePart}_$amountPart';
  if (collisionSuffix <= 1) {
    return '$base$ext';
  }
  return '$base-$collisionSuffix$ext';
}

/// Slug for plan line title (or transfer description) in file names.
String slugifyProofLineLabel(String label) {
  var s = label.trim();
  if (s.isEmpty) return 'depense';
  s = _stripDiacritics(s);
  s = s.replaceAll(RegExp(r'[^\w.\-]+'), '_');
  s = s.replaceAll(RegExp(r'_+'), '_');
  s = s.replaceAll(RegExp(r'^_|_$'), '');
  if (s.isEmpty) return 'depense';
  if (s.length > 48) {
    s = s.substring(0, 48).replaceAll(RegExp(r'_$'), '');
  }
  return s;
}

String lineLabelForProofFileName({
  required String kind,
  required String? planLineTitle,
  required String? description,
}) {
  if (RealizedExpenseKind.usesPlanLine(kind)) {
    final title = planLineTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return 'depense';
  }
  final desc = description?.trim();
  if (desc != null && desc.isNotEmpty) return desc;
  return 'transfert';
}

String extensionFromProofFileName(String fileName) {
  return _normalizeExtension(extensionFromFileName(fileName));
}

String mimeTypeForProofFileName(String fileName) {
  return switch (extensionFromProofFileName(fileName)) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    '.pdf' => 'application/pdf',
    '.txt' => 'text/plain',
    '.json' => 'application/json',
    _ => 'application/octet-stream',
  };
}

String extensionFromFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0 || dot >= fileName.length - 1) return '.bin';
  return fileName.substring(dot);
}

String _formatPaymentDate(DateTime paymentDate) {
  final local = paymentDate.toLocal();
  final y = local.year;
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatSubmissionTime(DateTime submittedAt) {
  final local = submittedAt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$h-$min';
}

String _normalizeExtension(String extension) {
  final trimmed = extension.trim();
  if (trimmed.isEmpty) return '.bin';
  return trimmed.startsWith('.') ? trimmed.toLowerCase() : '.${trimmed.toLowerCase()}';
}

String _stripDiacritics(String input) {
  const map = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ä': 'A',
    'Ã': 'A',
    'Å': 'A',
    'Ç': 'C',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Ì': 'I',
    'Í': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ñ': 'N',
    'Ò': 'O',
    'Ó': 'O',
    'Ô': 'O',
    'Ö': 'O',
    'Õ': 'O',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ý': 'Y',
  };
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}

