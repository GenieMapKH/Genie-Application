import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Chat / Call Now bar pinned to the bottom of the detail sheet.
class PropertyContactBar extends StatelessWidget {
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  const PropertyContactBar({super.key, this.onChat, this.onCall});

  static const double height = 76.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onChat,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: Color(0xFF111827),
                ),
                label: Text(
                  'Chat',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                label: Text(
                  'Call Now',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
