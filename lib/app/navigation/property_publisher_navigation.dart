import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_publisher_opener.dart';
import 'package:tilomnov/features/search/data/models/publisher_summary.dart';
import 'package:tilomnov/features/search/presentation/screens/publisher_profile_page.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_selection.dart';

/// Lets a listing open its publisher's profile page.
///
/// The profile page opens listings, so the listing does not import it: it
/// reaches the profile through this, supplied by the app.
PropertyPublisherOpener publisherFromListingOpener(Ref ref) {
  return (context, publisher) async {
    final navigator = Navigator.of(context);
    final selection = await navigator.push(
      PublisherProfilePage.route(
        PublisherSummary(
          id: publisher.userId,
          name: publisher.name,
          avatarUrl: publisher.avatarUrl,
        ),
      ),
    );

    // "View on map": leave the listing for the home map, showing theirs.
    if (selection is AreaSelection) {
      navigator.popUntil((route) => route.isFirst);
      ref.read(mainNavProvider.notifier).resetToHome();
      ref.read(searchAreaControllerProvider.notifier).show(selection.target);
    }
  };
}
