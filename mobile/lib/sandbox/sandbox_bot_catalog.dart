import 'dart:math';

import '../contacts/avatar_palette.dart';

/// Fixed ordered catalog of simulation bots (max 7).
class SandboxBotCatalog {
  SandboxBotCatalog._();

  static const List<String> displayNames = [
    'Louys',
    'Monica',
    'Ròberr',
    'Liuva',
    'Leo',
    'Germaine',
    'Youkie',
  ];

  static const int maxBots = 7;

  static String randomAvatarId([Random? random]) {
    final rng = random ?? Random();
    return AvatarPalette.idFor(rng.nextInt(AvatarPalette.length));
  }
}
