import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        color: Colors.white,
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
            color: const Color(0xFF5B5FEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Preview',
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
