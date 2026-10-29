import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/nearby_place.dart';
import 'package:tilomnov/features/property/data/models/property_keyword.dart';
import 'package:tilomnov/features/property/presentation/screens/nearby_route_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_nearby.dart';
import 'package:tilomnov/features/property/utils/nearby_distance_format.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// "What's nearby": the closest markets, hospitals and schools by road, for
/// the categories the seller tagged the listing near. Shows nothing for a
/// listing without those tags, or while it loads.
class PropertyNearbySection extends ConsumerWidget {
  final String propertyId;

  const PropertyNearbySection({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(propertyDetailProvider(propertyId));

    return detail.when(
      skipLoadingOnRefresh: false,
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        AppLogger.error('Nearby places failed to load', error, stack);
        return _CouldNotLoad(
          onRetry: () => ref.invalidate(propertyDetailProvider(propertyId)),
        );
      },
      data: (property) {
        final groups = nearbyGroupsOf(property);
        if (groups.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.propertyNearby,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.propertyNearbyCaption,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.colors.textMuted,
                ),
              ),
              for (final group in groups)
                _NearbyGroupView(
                  group: group,
                  propertyId: propertyId,
                  origin: property.lat == null || property.lng == null
                      ? null
                      : LatLng(property.lat!, property.lng!),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NearbyGroupView extends StatelessWidget {
  final NearbyGroup group;
  final String propertyId;

  /// Where the listing is; null when it is not placed on the map.
  final LatLng? origin;

  const _NearbyGroupView({
    required this.group,
    required this.propertyId,
    required this.origin,
  });

  String _title(BuildContext context) => switch (group.category) {
    'market' => context.l10n.propertyNearbyMarkets,
    'hospital' => context.l10n.propertyNearbyHospitals,
    _ => context.l10n.propertyNearbySchools,
  };

  @override
  Widget build(BuildContext context) {
    final keyword = NearbyPlace.keywordByCategory[group.category];
    final icon = PropertyKeyword.all
        .firstWhere((k) => k.code == keyword)
        .iconPath;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TintedSvg(
                icon,
                width: 18,
                height: 18,
                color: context.colors.highlight,
              ),
              const SizedBox(width: 8),
              Text(
                _title(context),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (group.places.isEmpty)
            Text(
              context.l10n.propertyNearbyNoneWithin(NearbyPlace.searchRadiusKm),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.colors.textMuted,
              ),
            )
          else
            for (final place in group.places)
              _NearbyPlaceRow(
                place: place,
                onTap: origin == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NearbyRoutePage(
                            propertyId: propertyId,
                            origin: origin!,
                            place: place,
                          ),
                        ),
                      ),
              ),
        ],
      ),
    );
  }
}

class _NearbyPlaceRow extends StatelessWidget {
  final NearbyPlace place;

  /// Opens the road on the map; null when the listing has no position.
  final VoidCallback? onTap;

  const _NearbyPlaceRow({required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    final road = place.roadMeters;
    final distance = formatNearbyDistance(
      context,
      road ?? place.straightMeters,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              road == null
                  ? context.l10n.propertyStraightLine(distance)
                  : distance,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: road == null ? FontWeight.w400 : FontWeight.w600,
                color: road == null
                    ? context.colors.textMuted
                    : context.colors.textPrimary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: context.colors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CouldNotLoad extends StatelessWidget {
  final VoidCallback onRetry;

  const _CouldNotLoad({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.propertyNearbyCouldNotLoad,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.colors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              context.l10n.commonRetry,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
