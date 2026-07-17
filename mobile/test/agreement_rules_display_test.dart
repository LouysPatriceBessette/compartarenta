import 'package:compartarenta/housing/agreement_rules_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAgreementBuildingRulesExampleText', () {
    const hintNoBullets =
        'Exemples à adapter :\nLogement non-fumeur\nPas d\'animaux\nRien dans les couloirs\n…';
    const hintWithBullets =
        'Exemples à adapter :\n• Logement non-fumeur\n• Pas d\'animaux\n• Rien dans les couloirs\n• …';

    test('matches current hint without bullets', () {
      expect(
        isAgreementBuildingRulesExampleText(hintNoBullets, hintNoBullets),
        isTrue,
      );
    });

    test('matches legacy hint with bullets against current hint', () {
      expect(
        isAgreementBuildingRulesExampleText(hintWithBullets, hintNoBullets),
        isTrue,
      );
    });

    test('does not match user-edited text', () {
      expect(
        isAgreementBuildingRulesExampleText('Pas de bugs!', hintNoBullets),
        isFalse,
      );
    });

    test('empty is not an example', () {
      expect(
        isAgreementBuildingRulesExampleText('', hintNoBullets),
        isFalse,
      );
    });
  });
}
