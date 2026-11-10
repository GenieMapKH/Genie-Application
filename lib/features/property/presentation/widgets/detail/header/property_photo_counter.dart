import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "3 / 12" in a dark pill: which photo is showing, of how many.
class PropertyPhotoCounter extends StatelessWidget {
  final int index;
  final int count;

  const PropertyPhotoCounter({
    super.key,
    required this.index,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            '${index + 1} / $count',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
