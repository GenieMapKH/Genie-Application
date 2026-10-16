import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:genie/features/search/data/models/publisher_profile.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/data/search_failure.dart';
import 'package:genie/features/search/presentation/search_layout.dart';
import 'package:genie/features/search/presentation/view_models/publisher_profile_provider.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';
import 'package:genie/features/search/presentation/widgets/profile/publisher_contact_card.dart';
import 'package:genie/features/search/presentation/widgets/profile/publisher_listings_grid.dart';
import 'package:genie/features/search/presentation/widgets/profile/publisher_profile_header.dart';
import 'package:genie/features/search/presentation/widgets/profile/publisher_profile_tabs.dart';
import 'package:genie/features/search/presentation/widgets/search_message_view.dart';
import 'package:genie/features/search/presentation/widgets/search_skeleton_list.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/transitions/app_page_route.dart';

/// A person's or agency's public profile, opened from search or from a
/// chat: who they are, then every listing they have published. Closes with
/// an [AreaSelection] when "View on map" is pressed.
class PublisherProfilePage extends ConsumerStatefulWidget {
  /// What the opener already knows, shown at once while the rest loads.
  final PublisherSummary person;

  /// What "Chat" does. Null opens a conversation with them; a chat that
  /// opened this page passes "go back to it" instead of stacking another.
  final VoidCallback? onChat;

  const PublisherProfilePage({super.key, required this.person, this.onChat});

  static Route<SearchSelection> route(
    PublisherSummary person, {
    VoidCallback? onChat,
  }) {
    return AppPageRoute<SearchSelection>(
      page: PublisherProfilePage(person: person, onChat: onChat),
    );
  }

  @override
  ConsumerState<PublisherProfilePage> createState() =>
      _PublisherProfilePageState();
}

class _PublisherProfilePageState extends ConsumerState<PublisherProfilePage> {
  var _tab = PublisherProfileTab.listings;

  PublisherSummary get person => widget.person;

  void _openChat(BuildContext context, PublisherSummary shown) {
    // The root navigator, as the listing page does: a full-screen chat.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(
          participantId: shown.id,
          participantName: shown.displayName,
        ),
      ),
    );
  }

  /// Widest the page grows; wider screens centre it.
  static const double _maxWidth = 960;

  void _openDetail(BuildContext context, PropertyModel property) {
    Navigator.of(context).push(
      PropertyDetailSheet.route(
        property,
        heroTag: 'saved_property_hero_${property.id}',
        onOpenProperty: (next) {
          Navigator.of(context).pop();
          _openDetail(context, next);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(publisherProfileProvider(person.id));
    final shown = profile.valueOrNull?.person ?? person;
    final hasListings = (profile.valueOrNull?.properties ?? const []).any(
      (p) => p.lat != null && p.lng != null,
    );
    final gutter = SearchLayout.gutter(MediaQuery.sizeOf(context).width);
    final isMe = ref.watch(userProfileProvider).valueOrNull?.id == person.id;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PublisherProfileHeader(
                  person: shown,
                  // TODO(follow): following comes in a later feature.
                  onFollow: () {},
                  onChat: isMe
                      ? null
                      : widget.onChat ?? () => _openChat(context, shown),
                  onViewOnMap: hasListings
                      ? () => Navigator.of(
                          context,
                        ).pop(AreaSelection(PersonTarget(shown)))
                      : null,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 20),
                sliver: SliverToBoxAdapter(
                  child: PublisherProfileTabBar(
                    selected: _tab,
                    onSelected: (tab) => setState(() => _tab = tab),
                  ),
                ),
              ),
              switch (_tab) {
                PublisherProfileTab.listings => _listings(
                  context,
                  profile,
                  gutter,
                ),
                PublisherProfileTab.about => _about(context, profile, gutter),
              },
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _failure(BuildContext context, Object error) {
    return SliverToBoxAdapter(
      child: SearchMessageView.failure(
        context,
        error is SearchFailure ? error.reason : SearchFailureReason.unknown,
        onRetry: () => ref.invalidate(publisherProfileProvider(person.id)),
      ),
    );
  }

  /// How to reach them; only the full profile carries it.
  Widget _about(
    BuildContext context,
    AsyncValue<PublisherProfile> profile,
    double gutter,
  ) {
    return profile.when(
      loading: () => SliverToBoxAdapter(
        child: SearchSkeletonList(rows: 2, gutter: gutter),
      ),
      error: (error, _) => _failure(context, error),
      data: (loaded) {
        final person = loaded.person;
        if (person.phone == null && person.email == null) {
          return SliverToBoxAdapter(
            child: SearchMessageView(
              icon: Icons.contact_phone_outlined,
              title: context.l10n.profileNoContact,
            ),
          );
        }
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: PublisherContactCard(person: person),
          ),
        );
      },
    );
  }

  Widget _listings(
    BuildContext context,
    AsyncValue<PublisherProfile> profile,
    double gutter,
  ) {
    return profile.when(
      loading: () => SliverToBoxAdapter(
        child: SearchSkeletonList(rows: 3, gutter: gutter),
      ),
      error: (error, _) => _failure(context, error),
      data: (loaded) {
        if (loaded.properties.isEmpty) {
          return SliverToBoxAdapter(
            child: SearchMessageView(
              icon: Icons.holiday_village_outlined,
              title: context.l10n.searchPersonEmpty,
            ),
          );
        }
        return PublisherListingsGrid(
          properties: loaded.properties,
          gutter: gutter,
          onOpen: (property) => _openDetail(context, property),
        );
      },
    );
  }
}
