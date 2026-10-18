import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/data/models/nearby_place.dart';
import 'package:genie/features/property/data/models/property_keyword.dart';
import 'package:genie/features/property/presentation/view_models/property_nearby.dart';
import 'package:genie/l10n/l10n.dart';

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
              for (final group in groups) _NearbyGroupView(group: group),
            ],
          ),
        );
      },
    );
  }
}

class _NearbyGroupView extends StatelessWidget {
  final NearbyGroup group;

  const _NearbyGroupView({required this.group});

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
              SvgPicture.asset(
                icon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  context.colors.highlight,
                  BlendMode.srcIn,
                ),
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
            for (final place in group.places) _NearbyPlaceRow(place: place),
        ],
      ),
    );
  }
}

class _NearbyPlaceRow extends StatelessWidget {
  final NearbyPlace place;

  const _NearbyPlaceRow({required this.place});

  /// 850 -> "850 m", 1640 -> "1.6 km".
  static String distance(BuildContext context, int meters) {
    if (meters < 1000) return context.l10n.propertyDistanceM(meters);
    return context.l10n.propertyDistanceKm((meters / 1000).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final road = place.roadMeters;
    final seconds = place.driveSeconds;
    final main = distance(context, road ?? place.straightMeters);
    final detail = road == null
        ? context.l10n.propertyStraightLine(main)
        : (seconds == null
              ? null
              : context.l10n.propertyDriveMinutes(
                  (seconds / 60).ceil().clamp(1, 999),
                ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (road != null)
                Text(
                  main,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              if (detail != null)
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.colors.textMuted,
                  ),
                ),
            ],
          ),
        ],
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
