import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/features/property/utils/property_share_link.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// The picture a listing is shared as: its lead photo, price and type, and a
/// QR code of its web page with the link written out.
///
/// Always in the light palette: it is sent to other people, whose theme is
/// not the sender's. Drawn [width] wide and saved at three times that.
class PropertyShareCard extends StatelessWidget {
  final PropertyModel property;

  /// The lead photo, already loaded so the picture is complete when taken;
  /// null draws the no-photo placeholder.
  final ImageProvider? photo;

  const PropertyShareCard({super.key, required this.property, this.photo});

  static const double width = 360;

  static const _colors = AppColors.light;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final link = propertyShareLink(property.id);

    return Container(
      width: width,
      color: _colors.primary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandRow(),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: _colors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _Photo(photo: photo),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _TypePill(propertyType: property.propertyType),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: _Details(property: property),
                  ),
                  Divider(height: 1, color: _colors.divider),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        QrImageView(
                          data: link.toString(),
                          version: QrVersions.auto,
                          size: 92,
                          padding: EdgeInsets.zero,
                          backgroundColor: _colors.surface,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: _colors.textPrimary,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: _colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.propertyShareScanToView,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${link.host}${link.path}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The app icon and name over the card.
class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset(
            'assets/images/brand/app_icon.png',
            width: 28,
            height: 28,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Tilomnov',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: PropertyShareCard._colors.onPrimary,
          ),
        ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  final ImageProvider? photo;

  const _Photo({required this.photo});

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (photo == null) return const _NoPhoto();
    return Image(
      image: photo,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _NoPhoto(),
    );
  }
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PropertyShareCard._colors.divider,
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 44,
          color: PropertyShareCard._colors.iconSubtle,
        ),
      ),
    );
  }
}

/// Price, spec line and title, as on the map card.
class _Details extends StatelessWidget {
  final PropertyModel property;

  const _Details({required this.property});

  @override
  Widget build(BuildContext context) {
    const colors = PropertyShareCard._colors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PropertyFormat.cardPrice(l10n, property),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          PropertyFormat.cardSpecLine(l10n, property),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        if (property.title.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            property.title.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  final String propertyType;

  const _TypePill({required this.propertyType});

  @override
  Widget build(BuildContext context) {
    const colors = PropertyShareCard._colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TintedSvg(
            PropertyFormat.typeIconPath(propertyType),
            width: 14,
            height: 14,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            propertyValueLabel(context.l10n, propertyType),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
