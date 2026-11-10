import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

import '../components/utm_section_title.dart';

class UtmManualEntry extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final List<Map<String, TextEditingController>> coordinateRows;
  final VoidCallback onAddRow;

  const UtmManualEntry({
    super.key,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.coordinateRows,
    required this.onAddRow,
  });

  @override
  Widget build(BuildContext context) {
    return // Manual Entry Section
    FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UtmSectionTitle(
                icon: (color) => TintedSvg(
                  'assets/icons/keyboard.svg',
                  width: 20,
                  height: 20,
                  color: color,
                ),
                title: context.l10n.homeEnterCoordinatesManually,
                subtitle: context.l10n.homeTypeUtmZoneEastingXAnd,
              ),
              const SizedBox(height: 16),

              // Table Headers
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '#',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'X',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Y',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Coordinate Rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: coordinateRows.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$index.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: TextField(
                            controller: coordinateRows[index]['x'],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              hintText: 'e.g. 485230',
                              hintStyle: GoogleFonts.inter(
                                color: context.colors.iconSubtle,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: TextField(
                            controller: coordinateRows[index]['y'],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              hintText: 'e.g. 1358420',
                              hintStyle: GoogleFonts.inter(
                                color: context.colors.iconSubtle,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Add Button
              Center(
                child: GestureDetector(
                  onTap: onAddRow,
                  child: Container(
                    width: 60,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: context.colors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
