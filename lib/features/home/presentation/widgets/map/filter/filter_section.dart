import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// A titled block of the filter page.
class FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const FilterSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [FilterLabel(title), const SizedBox(height: 10), child],
      ),
    );
  }
}

/// The bold heading over a filter control.
class FilterLabel extends StatelessWidget {
  final String text;

  const FilterLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.colors.textPrimary,
      ),
    );
  }
}

/// Two boxes side by side, each under its own label when given.
class FilterFieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;
  final String? firstLabel;
  final String? secondLabel;
  final String? errorText;

  const FilterFieldPair({
    super.key,
    required this.first,
    required this.second,
    this.firstLabel,
    this.secondLabel,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    Widget column(String? label, Widget field) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            FilterLabel(label),
            const SizedBox(height: 10),
          ],
          field,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            column(firstLabel, first),
            const SizedBox(width: 16),
            column(secondLabel, second),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.colors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
