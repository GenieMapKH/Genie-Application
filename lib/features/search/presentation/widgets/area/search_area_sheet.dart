import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/search/presentation/search_layout.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/focused_listing_bar.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_header.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_slide_up.dart';

/// The results panel on phones: a sheet dragged up over the map. While the
/// map is flown to one of its listings it collapses to its header and that
/// listing's bar, so the map shows.
class SearchAreaSheet extends StatefulWidget {
  final EdgeInsets margin;
  final Size? glassNav;
  final Widget header;

  /// The listing the map was flown to: the sheet collapses to show the map,
  /// keeping its bar and "View property" button in sight.
  final PropertyModel? focused;
  final ValueChanged<PropertyModel> onOpenProperty;
  final Widget listings;

  const SearchAreaSheet({
    super.key,
    required this.margin,
    required this.glassNav,
    required this.header,
    required this.focused,
    required this.onOpenProperty,
    required this.listings,
  });

  /// Grab handle above the header.
  static const double _handleHeight = 24;

  /// Collapsed to its handle and header, plus the bar of the listing the map
  /// was flown to while [focused].
  static double collapsedHeight({required bool focused}) =>
      _handleHeight +
      SearchAreaHeader.height +
      (focused ? FocusedListingBar.height : 0);

  @override
  State<SearchAreaSheet> createState() => _SearchAreaSheetState();
}

class _SearchAreaSheetState extends State<SearchAreaSheet> {
  static const _radius = 22.0;

  final _sheet = DraggableScrollableController();

  /// The sheet's list of cards, from its builder.
  ScrollController? _list;

  /// The collapsed size, as a fraction of the sheet's room, at the last
  /// layout.
  double _collapsedSize = 0;

  @override
  void didUpdateWidget(SearchAreaSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focused = widget.focused;
    if (focused == null || focused.id == oldWidget.focused?.id) return;
    // After this layout, which makes room for the listing's bar.
    WidgetsBinding.instance.addPostFrameCallback((_) => _collapse());
  }

  Future<void> _collapse() async {
    if (!mounted || !_sheet.isAttached) return;
    await _sheet.animateTo(
      _collapsedSize,
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );
    // A list scrolled down to the tapped card takes a drag up for itself,
    // not the sheet's: hidden behind the header, the sheet seemed stuck.
    // Now that the cards are out of sight, back to the top of them.
    final list = _list;
    if (!mounted || !_sheet.isAttached || list == null || !list.hasClients) {
      return;
    }
    if ((_sheet.size - _collapsedSize).abs() > 0.01) return;
    if (list.offset > 0) list.jumpTo(0);
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final margin = widget.margin;
    final focused = widget.focused;
    final colors = context.colors;
    final nav = widget.glassNav;
    final foot = nav?.height ?? 0.0;
    // Centred on the capsule, as wide as it.
    final side = nav == null
        ? 0.0
        : (MediaQuery.sizeOf(context).width - nav.width) / 2;
    final shape = BorderRadius.vertical(
      top: const Radius.circular(_radius),
      // Rounded like the capsule, so the two read as one shape.
      bottom: Radius.circular(foot / 2),
    );

    return Positioned(
      left: side,
      right: side,
      top: margin.top,
      bottom: margin.bottom,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxHeight;
          if (available <= foot) return const SizedBox.shrink();

          final resting =
              (SearchLayout.sheetRestingHeight(available - foot) + foot).clamp(
                0.0,
                available,
              );
          final collapsed =
              (SearchAreaSheet.collapsedHeight(focused: focused != null) + foot)
                  .clamp(0.0, resting);
          final initial = resting / available;
          _collapsedSize = collapsed / available;

          return SearchAreaSlideUp(
            child: DraggableScrollableSheet(
              controller: _sheet,
              initialChildSize: initial,
              minChildSize: collapsed / available,
              maxChildSize: 1,
              snap: true,
              snapSizes: [initial],
              builder: (context, scrollController) {
                _list = scrollController;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: shape,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: shape,
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        PinnedHeaderSliver(
                          child: ColoredBox(
                            color: colors.surface,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _GrabHandle(),
                                widget.header,
                                if (focused != null)
                                  FocusedListingBar(
                                    property: focused,
                                    onView: () =>
                                        widget.onOpenProperty(focused),
                                  ),
                                Divider(height: 1, color: colors.divider),
                              ],
                            ),
                          ),
                        ),
                        widget.listings,
                        // The last cards scroll up out from behind the nav.
                        SliverToBoxAdapter(child: SizedBox(height: 24 + foot)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SearchAreaSheet._handleHeight,
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.textHint,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
