import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/fields/property_select_field.dart';

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
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final int maxLines;
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
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: focusKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PropertySectionTitle(
              title: label,
              required: required,
              hasError: hasError,
            ),
            if (infoText != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 14,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      infoText!,
                      style: GoogleFonts.inter(
                        color: context.colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          maxLength: maxLength,
          maxLines: maxLines,
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
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PropertySectionTitle(
              title: label,
              required: required,
              hasError: hasError,
            ),
            if (infoText != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 14,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      infoText!,
                      style: GoogleFonts.inter(
                        color: context.colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        PropertySelectField(
          // A value this list does not offer (kept from another property
          // type) shows as unpicked.
          value: value,
          items: items,
          labelOf: (item) => propertyValueLabel(context.l10n, item),
          decoration: defaultPropertyInputDecoration(
            context,
            hintText ?? context.l10n.propertySelectHint,
            hasError: hasError,
          ),
          onChanged: onChanged,
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
