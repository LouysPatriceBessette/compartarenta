import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:compartarenta/widgets/app_text_field.dart';

void main() {
  group('resolveAppTextCapitalization', () {
    test('uses override when provided', () {
      expect(
        resolveAppTextCapitalization(
          text: '',
          capitalizationOverride: TextCapitalization.characters,
        ),
        TextCapitalization.characters,
      );
    });

    test('sentences when empty', () {
      expect(
        resolveAppTextCapitalization(text: ''),
        TextCapitalization.sentences,
      );
    });

    test('none when not empty', () {
      expect(
        resolveAppTextCapitalization(text: 'abc'),
        TextCapitalization.none,
      );
    });
  });

  testWidgets('empty AppTextField exposes sentences before focus', (
    tester,
  ) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: AppTextField(
          key: Key('name'),
          decoration: InputDecoration(labelText: 'Name'),
        ),
      ),
    ),
  );

  final textField = tester.widget<TextField>(find.byType(TextField));
  expect(textField.textCapitalization, TextCapitalization.sentences);
  });
}
