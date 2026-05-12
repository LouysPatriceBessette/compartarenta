import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// The 20-icon placeholder avatar collection used across onboarding,
/// housing, and contacts. Each entry is keyed by `mdi:<index>`; existing
/// stored avatar ids remain stable as long as the order is preserved.
class AvatarPalette {
  static const List<IconData> _icons = [
    MdiIcons.account,
    MdiIcons.accountCircle,
    MdiIcons.accountCowboyHat,
    MdiIcons.accountHeart,
    MdiIcons.accountStar,
    MdiIcons.alien,
    MdiIcons.cat,
    MdiIcons.dog,
    MdiIcons.penguin,
    MdiIcons.panda,
    MdiIcons.robot,
    MdiIcons.ninja,
    MdiIcons.pirate,
    MdiIcons.faceMan,
    MdiIcons.faceWoman,
    MdiIcons.emoticonHappyOutline,
    MdiIcons.emoticonCoolOutline,
    MdiIcons.ghost,
    MdiIcons.owl,
    MdiIcons.fish,
  ];

  static int get length => _icons.length;

  static String idFor(int index) => 'mdi:$index';

  static IconData iconFor(String avatarId) {
    if (!avatarId.startsWith('mdi:')) return _icons.first;
    final n = int.tryParse(avatarId.substring(4));
    if (n == null || n < 0 || n >= _icons.length) return _icons.first;
    return _icons[n];
  }

  static IconData iconAt(int index) => _icons[index];
}
