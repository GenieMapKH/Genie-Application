import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class UtmPreviewButton extends StatelessWidget {
  final VoidCallback onPreview;

  const UtmPreviewButton({super.key, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    return // Fixed Preview Button at bottom
    Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onPreview,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: context.colors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              context.l10n.homePreview,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
