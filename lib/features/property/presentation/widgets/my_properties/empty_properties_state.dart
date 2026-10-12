import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/theme/app_colors.dart';

class EmptyPropertiesState extends StatelessWidget {
  const EmptyPropertiesState({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 64.0,
          ), // Fixed vertical padding
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted, // Very light gray
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Don't expand to full height
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Home icon with alert. Using a stack with Material icons as a fallback.
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 64,
                    color: context.colors.iconSubtle,
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error,
                        size: 24,
                        color: context.colors.iconSubtle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "You haven't listed any\nproperty yet",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: context.colors.textHint,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
