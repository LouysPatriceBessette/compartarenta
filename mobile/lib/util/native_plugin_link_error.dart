import 'package:flutter/services.dart';

/// True when platform channels were never registered (common after Android hot restart).
bool isNativePluginLinkError(Object error) {
  if (error is MissingPluginException) return true;
  final text = error.toString();
  return text.contains('MissingPluginException') ||
      text.contains('No implementation found for method');
}

/// User-facing recovery steps when [isNativePluginLinkError] is true.
String nativePluginLinkErrorRecoveryMessage({String? languageCode}) {
  final fr = languageCode == 'fr';
  if (fr) {
    return 'Les plugins natifs (stockage local) ne sont pas chargés.\n\n'
        '1. Arrêtez la commande melos en cours (Ctrl+C dans le terminal)\n'
        '2. Quittez complètement l\'application sur l\'appareil\n'
        '3. Relancez : dart run melos run run:dev\n\n'
        'Si le problème persiste : cd mobile && ./tool/flutterw clean, '
        'puis relancez melos.';
  }
  return 'Native plugins (local storage) are not loaded.\n\n'
      '1. Stop the running melos command (Ctrl+C in the terminal)\n'
      '2. Force-quit the app on the device\n'
      '3. Start again: dart run melos run run:dev\n\n'
      'If it persists: cd mobile && ./tool/flutterw clean, then run melos again.';
}
