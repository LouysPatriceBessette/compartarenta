import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text_field.dart';

/// Centered numeric field with a fixed max width and trailing unit suffix.
class VehicleNarrowUnitField extends StatelessWidget {
  const VehicleNarrowUnitField({
    super.key,
    required this.controller,
    required this.label,
    required this.unitSuffix,
    this.decimal = false,
    this.onChanged,
  });

  static const double fieldMaxWidth = 200;

  final TextEditingController controller;
  final String label;
  final String unitSuffix;
  final bool decimal;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: fieldMaxWidth),
        child: AppTextField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: decimal
              ? null
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            suffixText: unitSuffix,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
