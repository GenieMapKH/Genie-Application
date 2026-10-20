import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:genie/features/property/presentation/widgets/property_item_card.dart';

/// Horizontally swipeable strip of property cards that slides in above the
/// bottom nav when a map property is selected.
///
/// Swiping a card left/right selects the next nearest property (which pans the
/// map to it); swiping up or tapping opens the full detail sheet.
class PropertyCarousel extends ConsumerStatefulWidget {
  /// Called when the user taps a card or flicks it upward.
  final void Function(PropertyModel property) onOpenDetail;

  const PropertyCarousel({super.key, required this.onOpenDetail});

  /// Total height the carousel occupies, including its card margins.
  static const double height = 280.0;

  /// Height of the bottom navigation bar the carousel sits above.
  static const double bottomNavHeight = 98.0;

  /// Map height hidden while the carousel is on screen.
  static const double mapInset = height + bottomNavHeight;

  @override
  ConsumerState<PropertyCarousel> createState() => _PropertyCarouselState();
}

class _PropertyCarouselState extends ConsumerState<PropertyCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.88,
  );

  /// The last non-empty list. Held so the cards stay on screen through the
  /// slide-out animation after the selection is cleared, and so the PageView
  /// (and therefore [_controller]) is never torn down mid-session.
  List<PropertyModel> _items = const [];

  /// Anchor of the list currently loaded in the PageView, so a brand new
  /// selection opens on its own card instead of animating across the list.
  String? _loadedAnchorId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the PageView aligned with selections made on the map.
  void _syncToState(
    PropertyCarouselState? previous,
    PropertyCarouselState next,
  ) {
    if (next.items.isEmpty) {
      _loadedAnchorId = null;
      return;
    }

    final anchorId = next.items.first.id;
    final isNewList = anchorId != _loadedAnchorId;
    _loadedAnchorId = anchorId;

    if (!_controller.hasClients) return;

    if (isNewList) {
      _controller.jumpToPage(next.index);
    } else if (_controller.page?.round() != next.index) {
      final isUserScrolling = _controller.position.isScrollingNotifier.value;
      if (!isUserScrolling) {
        _controller.animateToPage(
          next.index,
          duration: const Duration(milliseconds: 360),
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        );
      }
    }
  }

  void _handleVerticalDrag(DragEndDetails details, PropertyModel? property) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -220 && property != null) {
      widget.onOpenDetail(property);
    } else if (velocity > 260) {
      ref.read(propertyCarouselProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyCarouselProvider);
    ref.listen(propertyCarouselProvider, _syncToState);

    if (state.items.isNotEmpty) _items = state.items;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      offset: state.isVisible ? Offset.zero : const Offset(0, 1.25),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        opacity: state.isVisible ? 1 : 0,
        child: SizedBox(
          height: PropertyCarousel.height,
          child: _items.isEmpty
              ? const SizedBox.shrink()
              : IgnorePointer(
                  ignoring: !state.isVisible,
                  child: GestureDetector(
                    onVerticalDragEnd: (details) =>
                        _handleVerticalDrag(details, state.selected),
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _items.length,
                      onPageChanged: ref
                          .read(propertyCarouselProvider.notifier)
                          .setIndex,
                      itemBuilder: (context, index) {
                        final property = _items[index];
                        return Consumer(
                          builder: (context, ref, _) {
                            final isSaved = ref.watch(
                              isPropertySavedProvider(property.id),
                            );

                            return PropertyItemCard(
                              property: property,
                              isFavorite: isSaved,
                              onFavoriteToggled: () {
                                if (!requireSignIn(context, ref)) return;
                                ref
                                    .read(savedPropertyIdsProvider.notifier)
                                    .toggle(property.id);
                              },
                              onTap: () => widget.onOpenDetail(property),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
