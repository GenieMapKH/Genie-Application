import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UtmSheetHeader extends StatelessWidget {
  const UtmSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Locate Property',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24), // Balance the back button
        ],
      ),
    );
  }
}
