import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../util/fixed_decimal_input.dart';
import 'app_text_field.dart';

/// [AppTextField] that pads missing fractional digits when focus is lost.
///
/// Formatting runs only on blur (focus loss), never on [onChanged] or key events.
class AppDecimalTextField extends StatefulWidget {
  const AppDecimalTextField({
    super.key,
    required this.controller,
    required this.fractionDigits,
    this.signed = false,
    this.emptyBlurText,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.textInputAction,
    this.textCapitalization,
    this.style,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.inputFormatters,
    this.enabled,
    this.autofillHints = const <String>[],
    this.buildCounter,
  }) : assert(fractionDigits == 1 || fractionDigits == 2);

  final TextEditingController controller;
  final int fractionDigits;
  final bool signed;
  final String? emptyBlurText;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool readOnly;
  final bool canRequestFocus;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final Iterable<String>? autofillHints;
  final InputCounterWidgetBuilder? buildCounter;

  @override
  State<AppDecimalTextField> createState() => _AppDecimalTextFieldState();
}

class _AppDecimalTextFieldState extends State<AppDecimalTextField> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppDecimalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _ownedFocusNode?.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) return;
    _formatOnBlur();
  }

  void _formatOnBlur() {
    final before = widget.controller.text;
    applyFixedDecimalInputOnBlur(
      widget.controller,
      fractionDigits: widget.fractionDigits,
      signed: widget.signed,
      emptyBlurText: widget.emptyBlurText,
    );
    if (widget.controller.text != before) {
      widget.onChanged?.call(widget.controller.text);
    }
  }

  void _dismissKeyboard() {
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: widget.signed,
      ),
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      textAlign: widget.textAlign,
      readOnly: widget.readOnly,
      canRequestFocus: widget.canRequestFocus,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onEditingComplete: _dismissKeyboard,
      onSubmitted: (_) => _dismissKeyboard(),
      onTapOutside: (_) => _dismissKeyboard(),
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      buildCounter: widget.buildCounter,
    );
  }
}
