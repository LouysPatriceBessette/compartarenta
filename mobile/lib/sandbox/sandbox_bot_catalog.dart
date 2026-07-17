import 'dart:math';

import '../contacts/avatar_palette.dart';

/// Fixed ordered catalog of simulation bots (max 5).
class SandboxBotCatalog {
  SandboxBotCatalog._();

  static const List<String> displayNames = [
    'Louys',
    'Monica',
    'Ròberr',
    'Liuva',
    'Leo',
  ];

  static const int maxBots = 5;

  static String randomAvatarId([Random? random]) {
    final rng = random ?? Random();
    return AvatarPalette.idFor(rng.nextInt(AvatarPalette.length));
  }

  /// Stable unique avatar for catalog index [0, maxBots).
  ///
  /// Random palette picks collide often with 5 bots / 20 icons and used to
  /// mis-route housing proposals (same targetParticipantId to two bots).
  static String avatarIdForCatalogIndex(int index) {
    if (index < 0 || index >= AvatarPalette.length) {
      return randomAvatarId();
    }
    return AvatarPalette.idFor(index);
  }
}
