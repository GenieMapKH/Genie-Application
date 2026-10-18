import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/property/presentation/view_models/property_recommendations_provider.dart';
import 'package:genie/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:genie/features/property/presentation/widgets/detail/actions/property_contact_bar.dart';
import 'package:genie/features/property/presentation/widgets/detail/actions/property_detail_actions.dart';
import 'package:genie/features/property/presentation/widgets/detail/header/property_detail_gallery.dart';
import 'package:genie/features/property/presentation/widgets/detail/sections/property_nearby_section.dart';
import 'package:genie/features/property/presentation/widgets/detail/actions/property_owner_actions.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/property/presentation/widgets/detail/header/property_detail_summary.dart';
import 'package:genie/features/property/presentation/widgets/detail/sections/property_grid_section.dart';
import 'package:genie/features/property/presentation/widgets/detail/header/property_highlights.dart';
import 'package:genie/features/property/presentation/widgets/detail/sections/property_map_preview.dart';
import 'package:genie/features/property/presentation/widgets/detail/sections/property_share_section.dart';
import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/owner_display_name.dart';

/// Full-detail view for a property, opened by tapping or flicking up the map
/// card.
///
/// Presented as a draggable sheet with two snap stops: a brief stage showing the
/// lead photo and price summary, and a full stage revealing highlights, map
/// preview, sharing and recommendations. Dragging past the brief stage — or
/// scrolling the content — continues into the full stage in one gesture.
class PropertyDetailSheet extends ConsumerStatefulWidget {
  final PropertyModel property;
  final String? heroTag;

  /// Opens another property from the recommendation grids.
  final void Function(PropertyModel property)? onOpenProperty;

  const PropertyDetailSheet({
    super.key,
    required this.property,
    this.heroTag,
    this.onOpenProperty,
  });

  /// Fraction of the screen the sheet covers at the brief stage.
  static const double briefExtent = 0.62;

  /// Slides the sheet up over the map without hiding it at the brief stage.
  static Route<void> route(
    PropertyModel property, {
    String? heroTag,
    void Function(PropertyModel property)? onOpenProperty,
  }) {
    return PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => PropertyDetailSheet(
        property: property,
        heroTag: heroTag,
        onOpenProperty: onOpenProperty,
      ),
      transitionsBuilder: (_, animation, _, child) {
        final curveAnimation = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
          reverseCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
        );
        return FadeTransition(opacity: curveAnimation, child: child);
      },
    );
  }

  @override
  ConsumerState<PropertyDetailSheet> createState() =>
      _PropertyDetailSheetState();
}

class _PropertyDetailSheetState extends ConsumerState<PropertyDetailSheet> {
  bool _isDismissing = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Opened from anywhere (map, saved, a publisher's page): one more viewer.
    ref.read(visitedPropertyIdsProvider.notifier).recordView(widget.property.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) {
            setState(() => _isReady = true);
          }
        });
      }
    });
  }

  void _dismiss() {
    if (!_isDismissing && mounted) {
      _isDismissing = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = ref.watch(
      propertyRecommendationsProvider(widget.property.id),
    );

    final heroTag =
        widget.heroTag ?? 'property_card_hero_${widget.property.id}';

    // The owner manages the listing instead of contacting themselves.
    final viewerId = ref.watch(userProfileProvider).valueOrNull?.id;
    final isOwner = viewerId != null && viewerId == widget.property.ownerId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: Hero(
                tag: heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: RepaintBoundary(
                      child: ColoredBox(
                        color: context.colors.surface,
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      if (notification.metrics.axis ==
                                          Axis.vertical) {
                                        if (notification
                                            is ScrollUpdateNotification) {
                                          if (notification.metrics.pixels <
                                              -40) {
                                            _dismiss();
                                          }
                                        } else if (notification
                                            is OverscrollNotification) {
                                          if (notification.overscroll < -15) {
                                            _dismiss();
                                          }
                                        } else if (notification
                                            is ScrollEndNotification) {
                                          if (notification.metrics.pixels <
                                              -15) {
                                            _dismiss();
                                          }
                                        }
                                      }
                                      return false;
                                    },
                                    child: CustomScrollView(
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      slivers: [
                                        PropertyDetailGallery(
                                          imageUrls: widget.property.imageUrls,
                                        ),
                                        SliverToBoxAdapter(
                                          child: _Body(
                                            property: widget.property,
                                            recommendations: recommendations,
                                            onOpenProperty:
                                                widget.onOpenProperty,
                                            onDismiss: _dismiss,
                                            isReady: _isReady,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PropertyDetailActions(
                                    isFavorite:
                                        ref
                                            .watch(savedPropertiesProvider)
                                            .valueOrNull
                                            ?.any(
                                              (p) => p.id == widget.property.id,
                                            ) ??
                                        false,
                                    onClose: _dismiss,
                                    onFavoriteToggled: () {
                                      if (!requireSignIn(context, ref)) return;
                                      ref
                                          .read(
                                            savedPropertiesProvider.notifier,
                                          )
                                          .toggleFavorite(widget.property);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (isOwner)
                              PropertyOwnerActions(
                                property: widget.property,
                                onEdited: _dismiss,
                              )
                            else
                              PropertyContactBar(
                                onChat: () {
                                  if (!requireSignIn(context, ref)) return;
                                  if (widget.property.ownerId != null) {
                                    // Use root navigator so chat opens as a full-screen page
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChatConversationPage(
                                              participantId:
                                                  widget.property.ownerId!,
                                              participantName: ownerDisplayName(
                                                context.l10n,
                                                widget.property.ownerName,
                                              ),
                                            ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context
                                              .l10n
                                              .propertyCannotChatOwnerInformationMissing,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onCall: () {},
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything below the photo gallery.
class _Body extends StatelessWidget {
  final PropertyModel property;
  final PropertyRecommendations recommendations;
  final void Function(PropertyModel property)? onOpenProperty;
  final VoidCallback? onDismiss;
  final bool isReady;

  const _Body({
    required this.property,
    required this.recommendations,
    this.onOpenProperty,
    this.onDismiss,
    this.isReady = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Lifted over the last photo, matching the rounded card in the design.
      transform: Matrix4.translationValues(0, -20, 0),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(onDismiss: onDismiss),
          const SizedBox(height: 14),
          PropertyDetailSummary(property: property),
          if (isReady) ...[
            const _SectionGap(),
            PropertyHighlights(property: property),
            const _SectionGap(),
            PropertyMapPreview(
              property: property,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            // Below where the listing is: how near "near market" really is.
            PropertyNearbySection(propertyId: property.id),
            const _SectionGap(),
            PropertyShareSection(property: property),
            if (recommendations.similar.isNotEmpty) ...[
              const _SectionGap(),
              PropertyGridSection(
                title: context.l10n.propertySimilarProperty,
                properties: recommendations.similar,
                onPropertyTapped: (p) => onOpenProperty?.call(p),
              ),
            ],
            if (recommendations.forYou.isNotEmpty) ...[
              const _SectionGap(),
              PropertyGridSection(
                title: context.l10n.propertyPropertyForYou,
                properties: recommendations.forYou,
                onPropertyTapped: (p) => onOpenProperty?.call(p),
              ),
            ],
          ] else ...[
            const SizedBox(height: 300),
          ],
        ],
      ),
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 28);
}

class _DragHandle extends StatelessWidget {
  final VoidCallback? onDismiss;

  const _DragHandle({this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 100) {
          onDismiss?.call();
        }
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 5) {
          onDismiss?.call();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.iconSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
