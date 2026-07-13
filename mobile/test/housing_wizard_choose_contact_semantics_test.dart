import 'package:compartarenta/debug/qa_housing_proposal_semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('qa-housing-wizard-choose-contact exposes a tappable semantics node',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            explicitChildNodes: true,
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Co-participant 1'),
                const Text('Choisissez un contact pour chaque participant.'),
                qaHousingProposalSemantics(
                  identifier: kQaHousingWizardChooseContact,
                  button: true,
                  onTap: () => tapped = true,
                  child: FilledButton.icon(
                    onPressed: () => tapped = true,
                    icon: const Icon(Icons.contacts),
                    label: const Text('Choisir un contact'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsIdentifier(kQaHousingWizardChooseContact),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsIdentifier(kQaHousingWizardChooseContact));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
