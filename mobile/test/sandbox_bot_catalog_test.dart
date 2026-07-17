import 'package:compartarenta/sandbox/sandbox_bot_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog avatars are unique across maxBots', () {
    final ids = {
      for (var i = 0; i < SandboxBotCatalog.maxBots; i++)
        SandboxBotCatalog.avatarIdForCatalogIndex(i),
    };
    expect(ids, hasLength(SandboxBotCatalog.maxBots));
  });
}
