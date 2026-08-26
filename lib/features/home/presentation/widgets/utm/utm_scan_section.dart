import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                  'Use UTM from a land document or enter coordinates manually',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CRS: WGS84 / UTM Zone 48P',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
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
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.document_scanner_outlined,
                        size: 40,
                        color: Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan UTM from Document',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use camera to detect coordinates',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                              ),
                            Center(
                              child: isScanning
                                  ? Text(
                                      uploadProgress < 1.0
                                          ? 'Processing...'
                                          : 'Finished',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF374151),
                                      ),
                                    )
                                  : Text(
                                      'Start Scanning',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF374151),
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
