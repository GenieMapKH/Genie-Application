import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// The heading of one section of a legal page (terms, privacy).
class LegalSectionHeader extends StatelessWidget {
  final String text;

  const LegalSectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}

/// A paragraph of a legal page.
class LegalParagraph extends StatelessWidget {
  final String text;

  const LegalParagraph(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: context.colors.textSecondary,
        height: 1.5,
      ),
    );
  }
}

/// One point of a bulleted list on a legal page.
class LegalBullet extends StatelessWidget {
  final String text;

  const LegalBullet(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7.0, right: 8.0),
            child: Icon(Icons.circle, size: 4.5, color: color),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: color,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
