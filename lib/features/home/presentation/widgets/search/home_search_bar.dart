import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/map_camera_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_capsule.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/search/presentation/screens/search_page.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_selection.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';

/// The search bar over the map. Opens the search page; once a place or a
/// person is picked it shows their name, with a button to clear it.
class HomeSearchBar extends ConsumerWidget {
  /// Called when a single listing is picked from the results.
  final ValueChanged<PropertyModel> onOpenProperty;

  const HomeSearchBar({super.key, required this.onOpenProperty});

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final active = ref.read(searchAreaControllerProvider)?.target;
    final selection = await Navigator.of(context).push(
      SearchPage.route(
        near: ref.read(mapCameraProvider).center,
        initialText: active?.title ?? '',
      ),
    );
    if (selection == null) return;

    switch (selection) {
      case AreaSelection(:final target):
        ref.read(searchAreaControllerProvider.notifier).show(target);
      case PropertySelection(:final property):
        onOpenProperty(property);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final active = ref.watch(
      searchAreaControllerProvider.select((state) => state?.target),
    );

    final glass = watchGlassNavigation(ref, context);

    return TactileButton(
      onPressed: () => _openSearch(context, ref),
      child: MapCapsule(
        height: 48,
        padding: EdgeInsets.only(left: 16, right: active == null ? 16 : 4),
        ring: false,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        child: Row(
          children: [
            SvgPicture.asset('assets/icons/search.svg', width: 24, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                active?.title ?? context.l10n.homeSearchByAreaRoadVillage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  // The hint is muted; over glass it needs a little more.
                  color: active != null
                      ? colors.textPrimary
                      : glass
                      ? colors.textSecondary
                      : colors.textMuted,
                  fontSize: 14,
                  fontWeight: active == null
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ),
            if (active != null)
              IconButton(
                onPressed: () =>
                    ref.read(searchAreaControllerProvider.notifier).clear(),
                tooltip: context.l10n.searchClear,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: colors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
