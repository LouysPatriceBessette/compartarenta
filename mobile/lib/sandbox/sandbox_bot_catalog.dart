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
}
