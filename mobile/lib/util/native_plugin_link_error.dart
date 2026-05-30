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
        '2. Désinstallez « Compartarenta (Dev) » sur l\'appareil '
        '(réglages Android → Applications), pas seulement la fermer\n'
        '3. Dans le dépôt : dart run melos run run:dev '
        '(réinstalle l\'APK ; ne rouvrez pas l\'app avant la fin de « Installing… »)\n'
        '4. Si l\'erreur persiste seulement alors : flutter clean + codegen '
        '(évitez d\'ouvrir le web sans run:dev:web — voir ci-dessous)\n\n'
        'Web : stockage séparé d\'Android ; utilisez run:dev:web (port 5001).\n\n'
        'Vérifiez que vous lancez bien Compartarenta (Dev) (flavor dev), '
        'pas une autre variante installée à part.';
  }
  return 'Native plugins (local storage) are not loaded.\n\n'
      '1. Stop the running melos command (Ctrl+C in the terminal)\n'
      '2. Uninstall “Compartarenta (Dev)” on the device '
      '(Android Settings → Apps), do not only force-quit\n'
      '3. In the repo: dart run melos run run:dev '
      '(reinstalls the APK; do not open the app until “Installing…” finishes)\n'
      '4. Only if it still fails: flutter clean + codegen '
      '(do not open web without run:dev:web — see below)\n\n'
      'Web: storage is separate from Android; use run:dev:web (port 5001).\n\n'
      'Make sure you open Compartarenta (Dev) (dev flavor), not another '
      'installed variant.';
}
