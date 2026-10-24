import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/utils/property_format.dart';

/// A number box of the filter page. Empty means "no limit" (null). It follows
/// [value] when something else changes it, such as the price slider.
class FilterNumberField extends StatefulWidget {
  final String hint;
  final double? value;
  final ValueChanged<double?> onChanged;
  final bool hasError;

  const FilterNumberField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<FilterNumberField> createState() => _FilterNumberFieldState();
}

class _FilterNumberFieldState extends State<FilterNumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );

  static String _format(double? value) =>
      value == null ? '' : PropertyFormat.size(value);

  static double? _parse(String text) => double.tryParse(text);

  @override
  void didUpdateWidget(FilterNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        _parse(_controller.text) != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
    final edge = widget.hasError ? colors.danger : colors.border;

    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: (text) => widget.onChanged(_parse(text)),
      style: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: colors.textHint),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: border(edge),
        focusedBorder: border(widget.hasError ? colors.danger : colors.primary),
      ),
    );
  }
}
