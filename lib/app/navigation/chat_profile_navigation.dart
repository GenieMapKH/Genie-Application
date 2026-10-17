import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/chat/providers/chat_profile_opener.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/presentation/screens/publisher_profile_page.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';

/// Lets a conversation open the other person's profile page.
///
/// Chat and the profile page each open the other, so neither feature
/// imports the other's page in both directions: the profile page opens chat
/// directly, and chat reaches the profile through this, supplied by the app.
ChatProfileOpener profileFromChatOpener(Ref ref) {
  return (context, target) async {
    final navigator = Navigator.of(context);
    final selection = await navigator.push(
      PublisherProfilePage.route(
        PublisherSummary(
          id: target.userId,
          name: target.name,
          username: target.username,
          avatarUrl: target.avatarUrl,
        ),
        // Already in their chat: "Chat" goes back to it.
        onChat: () => navigator.pop(),
      ),
    );

    // "View on map": leave chat for the home map, showing their listings.
    if (selection is AreaSelection) {
      navigator.popUntil((route) => route.isFirst);
      ref.read(mainNavProvider.notifier).resetToHome();
      ref.read(searchAreaControllerProvider.notifier).show(selection.target);
    }
  };
}
