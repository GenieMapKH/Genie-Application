import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/search/data/search_history_repository.dart';
import 'package:genie/features/search/data/search_repository.dart';

/// Kept for the whole app session, so its recent answers outlive the page.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  return SearchHistoryRepository(ref.watch(apiClientProvider));
});

/// Whether someone is signed in: guests have no search history.
final searchHasSessionProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final token = await AuthStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  };
});
