import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/theme/app_colors.dart';

class PropertySectionTitle extends StatelessWidget {
  final String title;
  final bool required;
  final bool hasError;

  const PropertySectionTitle({
    super.key,
    required this.title,
    this.required = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: title,
        style: GoogleFonts.inter(
          color: hasError
              ? const Color(0xFFE5484D)
              : context.colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.inter(color: const Color(0xFFE5484D)),
                ),
              ]
            : [],
      ),
    );
  }
}

class PropertyTextField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String hintText;
  final String? infoText;
  final bool hasError;
  final Key? focusKey;

  const PropertyTextField({
    super.key,
    required this.label,
    this.required = false,
    required this.controller,
    required this.hintText,
    this.infoText,
    this.hasError = false,
    this.focusKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: focusKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: label,
              required: required,
              hasError: hasError,
            ),
            if (infoText != null)
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    infoText!,
                    style: GoogleFonts.inter(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: defaultPropertyInputDecoration(
            context,
            hintText,
            hasError: hasError,
          ),
        ),
      ],
    );
  }
}

class PropertyDropdown extends StatelessWidget {
  final String label;
  final bool required;
  final String? value;
  final String? hintText;
  final List<String> items;
  final Function(String?) onChanged;
  final bool hasError;
  final Key? focusKey;
  final String? infoText;

  const PropertyDropdown({
    super.key,
    required this.label,
    this.required = false,
    required this.value,
    this.hintText,
    required this.items,
    required this.onChanged,
    this.hasError = false,
    this.focusKey,
    this.infoText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: focusKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: label,
              required: required,
              hasError: hasError,
            ),
            if (infoText != null)
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    infoText!,
                    style: GoogleFonts.inter(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: context.colors.textHint),
          style: GoogleFonts.inter(
            color: context.colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: context.colors.surface,
          borderRadius: BorderRadius.circular(12.0),
          decoration: defaultPropertyInputDecoration(
            context,
            hintText ?? 'Select',
            hasError: hasError,
          ),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
        ),
      ],
    );
  }
}

InputDecoration defaultPropertyInputDecoration(
  BuildContext context,
  String hint, {
  bool hasError = false,
}) {
  final borderColor = hasError
      ? const Color(0xFFE5484D)
      : context.colors.border;
  final hintColor = hasError
      ? const Color(0xFFE5484D)
      : context.colors.textHint;

  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(
        color: hasError ? borderColor : context.colors.primaryStrong,
      ),
    ),
  );
}
