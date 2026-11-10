import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/header/property_photo_column.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/header/property_photo_counter.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/property_photo_viewer.dart';

/// The detail sheet of a listing with several photos: the photos stacked
/// behind, the description as a card over them.
///
/// The card first rests under the first photo, like the one-photo cover.
/// Scrolling the photos slides it down to a peek of the price, so they can
/// be looked through; dragging it up brings the description back, and on
/// up over the photos to read all of it. Tapping a photo opens it full
/// screen.
class PropertyDetailPhotoLayout extends StatefulWidget {
  final List<String> imageUrls;

  /// Same order and length as [imageUrls] (see `PropertyModel.cardImageUrls`).
  final List<String> thumbnailUrls;

  /// Names photos saved from the full-screen viewer.
  final String propertyId;

  /// The description card's content.
  final Widget body;

  /// Scrolling of the photos, so pulling them down past the top can close
  /// the sheet.
  final NotificationListenerCallback<ScrollNotification> onPhotosScrolled;

  const PropertyDetailPhotoLayout({
    super.key,
    required this.imageUrls,
    required this.thumbnailUrls,
    required this.propertyId,
    required this.body,
    required this.onPhotosScrolled,
  });

  /// How much of the card stays in sight when the photos are scrolled: the
  /// handle and the price.
  static const double peekHeight = 132;

  /// How far the resting card overlaps the bottom of the first photo.
  static const double _overlap = 20;

  static const double _radius = 20;

  /// Photo height for a sheet [width] wide.
  static double photoHeightFor(double width) =>
      (width * 0.68).clamp(220.0, 520.0);

  @override
  State<PropertyDetailPhotoLayout> createState() =>
      _PropertyDetailPhotoLayoutState();
}

class _PropertyDetailPhotoLayoutState extends State<PropertyDetailPhotoLayout> {
  final _photos = ScrollController();
  final _card = DraggableScrollableController();
  final _shown = ValueNotifier<int>(0);

  /// The card's sizes, as fractions of the layout's height, at the last
  /// layout.
  double _peek = 0.2;
  double _resting = 0.6;
  double _photoHeight = PropertyDetailPhotoLayout.photoHeightFor(400);

  /// Whether the card is on its way down to the peek.
  bool _lowering = false;

  @override
  void initState() {
    super.initState();
    _photos.addListener(_onPhotosMoved);
  }

  @override
  void dispose() {
    _photos.dispose();
    _card.dispose();
    _shown.dispose();
    super.dispose();
  }

  PropertyPhotoColumn _column(double bottomPadding) => PropertyPhotoColumn(
    imageUrls: widget.imageUrls,
    thumbnailUrls: widget.thumbnailUrls,
    controller: _photos,
    photoHeight: _photoHeight,
    bottomPadding: bottomPadding,
    onTapPhoto: _openViewer,
  );

  void _onPhotosMoved() {
    final offset = _photos.offset;
    _shown.value = _column(0).indexAt(offset);

    // Looking through the photos: the card steps out of their way.
    if (offset <= 12 || _lowering || !_card.isAttached) return;
    if (_card.size <= _peek + 0.01) return;
    _lowering = true;
    _card
        .animateTo(
          _peek,
          duration: const Duration(milliseconds: 320),
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        )
        .whenComplete(() => _lowering = false);
  }

  Future<void> _openViewer(int index) async {
    final shownLast = await PropertyPhotoViewer.open(
      context,
      imageUrls: widget.imageUrls,
      thumbnailUrls: widget.thumbnailUrls,
      initialIndex: index,
      propertyId: widget.propertyId,
    );
    // Back on the photo looked at last.
    if (shownLast == null || shownLast == index) return;
    if (!mounted || !_photos.hasClients) return;
    _photos.jumpTo(
      math.min(
        _column(0).offsetOf(shownLast),
        _photos.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        _photoHeight = PropertyDetailPhotoLayout.photoHeightFor(
          constraints.maxWidth,
        );
        final peek = math.min(
          PropertyDetailPhotoLayout.peekHeight,
          height * 0.4,
        );
        _peek = peek / height;
        // Snapping needs the resting size strictly between the two ends.
        _resting =
            ((height - _photoHeight + PropertyDetailPhotoLayout._overlap) /
                    height)
                .clamp(_peek + 0.05, 0.95);

        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: widget.onPhotosScrolled,
              child: _column(peek),
            ),
            _counter(height),
            DraggableScrollableSheet(
              controller: _card,
              initialChildSize: _resting,
              minChildSize: _peek,
              maxChildSize: 1,
              snap: true,
              snapSizes: [_resting],
              builder: (context, scrollController) => _DescriptionCard(
                controller: scrollController,
                body: widget.body,
              ),
            ),
          ],
        );
      },
    );
  }

  /// "3 / 12" just above the card, wherever it is dragged.
  Widget _counter(double height) {
    return AnimatedBuilder(
      animation: _card,
      builder: (context, child) {
        final size = _card.isAttached ? _card.size : _resting;
        return Positioned(
          right: 12,
          bottom: size * height - PropertyDetailPhotoLayout._overlap + 10,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: size > 0.95 ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: child,
            ),
          ),
        );
      },
      child: ValueListenableBuilder<int>(
        valueListenable: _shown,
        builder: (context, index, _) =>
            PropertyPhotoCounter(index: index, count: widget.imageUrls.length),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final ScrollController controller;
  final Widget body;

  const _DescriptionCard({required this.controller, required this.body});

  @override
  Widget build(BuildContext context) {
    const shape = BorderRadius.vertical(
      top: Radius.circular(PropertyDetailPhotoLayout._radius),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
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
          controller: controller,
          slivers: [SliverToBoxAdapter(child: body)],
        ),
      ),
    );
  }
}
