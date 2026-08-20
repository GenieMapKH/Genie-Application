import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          color: hasError ? const Color(0xFFE5484D) : const Color(0xFF111827),
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
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    infoText!,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
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
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    infoText!,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          decoration: defaultPropertyInputDecoration(
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
  String hint, {
  bool hasError = false,
}) {
  final borderColor = hasError
      ? const Color(0xFFE5484D)
      : const Color(0xFFE5E7EB);
  final hintColor = hasError
      ? const Color(0xFFE5484D)
      : const Color(0xFF9CA3AF);

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
        color: hasError ? borderColor : const Color(0xFF3E49C7),
      ),
    ),
  );
}
