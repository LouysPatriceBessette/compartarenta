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
        '1. Arrêtez toute commande melos / flutter (Ctrl+C)\n'
        '2. Fermeture forcée de « Bojairũ (Dev) » (pas seulement retour arrière) '
        'et retrait des recents Android\n'
        '3. Désinstallez « Bojairũ (Dev) » (Réglages → Applications)\n'
        '4. Branchez l\'appareil (adb devices) puis, dans le dépôt :\n'
        '   dart run melos run run:dev\n'
        '5. N\'ouvrez pas l\'app depuis l\'icône : attendez la fin de '
        '« Installing… » et laissez Flutter la lancer\n'
        '6. Si l\'erreur persiste :\n'
        '   COMPARTARENTA_RUN_RAW_LOGS=1 dart run melos run run:dev\n'
        '   puis dart run melos run refresh\n\n'
        'Web : stockage séparé ; utilisez run:dev:web (port 5001).\n\n'
        'Vérifiez le flavor dev (Bojairũ (Dev)), pas staging/prod.';
  }
  return 'Native plugins (local storage) are not loaded.\n\n'
      '1. Stop every melos / flutter command (Ctrl+C)\n'
      '2. Force-stop “Bojairũ (Dev)” (not just back) and remove it from '
      'Android recents\n'
      '3. Uninstall “Bojairũ (Dev)” (Settings → Apps)\n'
      '4. Connect the device (adb devices), then in the repo:\n'
      '   dart run melos run run:dev\n'
      '5. Do not open the app from the launcher: wait until “Installing…” '
      'finishes and let Flutter launch it\n'
      '6. If it still fails:\n'
      '   COMPARTARENTA_RUN_RAW_LOGS=1 dart run melos run run:dev\n'
      '   then dart run melos run refresh\n\n'
      'Web: separate storage; use run:dev:web (port 5001).\n\n'
      'Use the dev flavor (Bojairũ (Dev)), not staging/prod.';
}
