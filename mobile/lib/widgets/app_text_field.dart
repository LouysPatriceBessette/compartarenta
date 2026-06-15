import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shift-on for the first letter while the field is still empty.
///
/// Capitalization is tied to emptiness, not focus alone: mobile keyboards read
/// [TextCapitalization] when the IME connects (on focus). Waiting for a focus
/// listener would rebuild too late and leave shift off.
TextCapitalization resolveAppTextCapitalization({
  required String text,
  TextCapitalization? capitalizationOverride,
}) {
  if (capitalizationOverride != null) return capitalizationOverride;
  if (text.isEmpty) return TextCapitalization.sentences;
  return TextCapitalization.none;
}

class _TextCapitalizationHost extends StatefulWidget {
  const _TextCapitalizationHost({
    this.controller,
    this.focusNode,
    this.initialValue,
    this.capitalizationOverride,
    required this.childBuilder,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final TextCapitalization? capitalizationOverride;
  final Widget Function(FocusNode focusNode, TextCapitalization capitalization)
      childBuilder;

  @override
  State<_TextCapitalizationHost> createState() =>
      _TextCapitalizationHostState();
}

class _TextCapitalizationHostState extends State<_TextCapitalizationHost> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_rebuild);
    widget.controller?.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant _TextCapitalizationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_rebuild);
      widget.controller?.addListener(_rebuild);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_rebuild);
      _focusNode.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_rebuild);
    _ownedFocusNode?.removeListener(_rebuild);
    widget.controller?.removeListener(_rebuild);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final text = widget.controller?.text ?? widget.initialValue ?? '';
    final capitalization = resolveAppTextCapitalization(
      text: text,
      capitalizationOverride: widget.capitalizationOverride,
    );
    return widget.childBuilder(_focusNode, capitalization);
  }
}

/// App-wide [TextField] with shift enabled on focus when the field is empty.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    this.style,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.inputFormatters,
    this.enabled,
    this.autofillHints = const <String>[],
    this.buildCounter,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool readOnly;
  final bool canRequestFocus;
  final bool autofocus;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final Iterable<String>? autofillHints;
  final InputCounterWidgetBuilder? buildCounter;

  @override
  Widget build(BuildContext context) {
    return _TextCapitalizationHost(
      controller: controller,
      focusNode: focusNode,
      capitalizationOverride: textCapitalization,
      childBuilder: (effectiveFocusNode, capitalization) => TextField(
        controller: controller,
        focusNode: effectiveFocusNode,
        decoration: decoration,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: capitalization,
        style: style,
        textAlign: textAlign,
        readOnly: readOnly,
        canRequestFocus: canRequestFocus,
        autofocus: autofocus,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        onSubmitted: onSubmitted,
        onTap: onTap,
        onTapOutside: onTapOutside,
        inputFormatters: inputFormatters,
        enabled: enabled,
        autofillHints: autofillHints,
        buildCounter: buildCounter,
      ),
    );
  }
}

/// App-wide [TextFormField] with shift enabled on focus when the field is empty.
class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    this.style,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onTap,
    this.onTapOutside,
    this.inputFormatters,
    this.enabled,
    this.autofillHints = const <String>[],
    this.validator,
    this.autovalidateMode,
    this.buildCounter,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool readOnly;
  final bool canRequestFocus;
  final bool autofocus;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final InputCounterWidgetBuilder? buildCounter;

  @override
  Widget build(BuildContext context) {
    return _TextCapitalizationHost(
      controller: controller,
      focusNode: focusNode,
      initialValue: initialValue,
      capitalizationOverride: textCapitalization,
      childBuilder: (effectiveFocusNode, capitalization) => TextFormField(
        controller: controller,
        focusNode: effectiveFocusNode,
        initialValue: initialValue,
        decoration: decoration,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: capitalization,
        style: style,
        textAlign: textAlign,
        readOnly: readOnly,
        canRequestFocus: canRequestFocus,
        autofocus: autofocus,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        onFieldSubmitted: onFieldSubmitted,
        onTap: onTap,
        onTapOutside: onTapOutside,
        inputFormatters: inputFormatters,
        enabled: enabled,
        autofillHints: autofillHints,
        validator: validator,
        autovalidateMode: autovalidateMode,
        buildCounter: buildCounter,
      ),
    );
  }
}
