import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

class UtmScanSection extends StatelessWidget {
  final Animation<double> fadeAnimation1;
  final Animation<Offset> slideAnimation1;
  final Animation<double> fadeAnimation2;
  final Animation<Offset> slideAnimation2;
  final bool isScanning;
  final double uploadProgress;
  final VoidCallback onScanDocument;

  const UtmScanSection({
    super.key,
    required this.fadeAnimation1,
    required this.slideAnimation1,
    required this.fadeAnimation2,
    required this.slideAnimation2,
    required this.isScanning,
    required this.uploadProgress,
    required this.onScanDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Text
        FadeTransition(
          opacity: fadeAnimation1,
          child: SlideTransition(
            position: slideAnimation1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeUseUtmFromALandDocument,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.homeCrsWgs84UtmZone48p,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Scan Section
        FadeTransition(
          opacity: fadeAnimation2,
          child: SlideTransition(
            position: slideAnimation2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 40,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.homeScanUtmFromDocument,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.homeUseCameraToDetectCoordinates,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: isScanning ? null : onScanDocument,
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            if (isScanning)
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: uploadProgress,
                                  child: Container(
                                    color: context.colors.border,
                                  ),
                                ),
                              ),
                            Center(
                              child: isScanning
                                  ? Text(
                                      uploadProgress < 1.0
                                          ? context.l10n.homeScanProcessing
                                          : context.l10n.homeScanFinished,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.textSecondary,
                                      ),
                                    )
                                  : Text(
                                      context.l10n.homeStartScanning,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
