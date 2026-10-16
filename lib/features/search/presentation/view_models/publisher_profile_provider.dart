import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/search/data/models/publisher_profile.dart';
import 'package:genie/features/search/presentation/view_models/search_providers.dart';

/// A publisher's profile by user id, loaded while their page is open.
final publisherProfileProvider = FutureProvider.autoDispose
    .family<PublisherProfile, String>((ref, userId) {
      return ref.read(searchRepositoryProvider).publisherProfile(userId);
    });
