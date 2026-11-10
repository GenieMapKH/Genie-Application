import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/property/data/models/map_property_filter.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/search/data/saved_search_repository.dart';
import 'package:tilomnov/features/search/presentation/view_models/saved_searches_provider.dart';
import 'package:tilomnov/features/search/presentation/widgets/saved/saved_search_name_dialog.dart';
import 'package:tilomnov/features/search/presentation/widgets/saved/saved_search_summary.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// Saves the area the map shows with [filter], under a name the user
/// gives. A guest is asked to sign in first. True when saved.
Future<bool> saveMapSearch(
  BuildContext context,
  WidgetRef ref, {
  required MapPropertyFilter filter,
}) async {
  if (!requireSignIn(context, ref)) return false;
  final l10n = context.l10n;
  final area = ref.read(mapBoundsProvider);
  if (area == null) {
    AppPopup.showError(context, l10n.savedSearchNoArea);
    return false;
  }

  final name = await showSavedSearchNameDialog(
    context,
    title: l10n.savedSearchSaveTitle,
    initialName: savedSearchSummary(l10n, filter),
    help: l10n.savedSearchSaveHelp,
  );
  if (name == null || !context.mounted) return false;

  final failure = await ref
      .read(savedSearchesProvider.notifier)
      .save(name: name, area: area, filter: filter);
  if (!context.mounted) return failure == null;
  switch (failure) {
    case null:
      AppPopup.showSuccess(context, l10n.savedSearchSaved);
    case SaveSearchFailure.limitReached:
      AppPopup.showError(context, l10n.savedSearchLimit(maxSavedSearches));
    case SaveSearchFailure.failed:
      showFailure(context, fallback: l10n.savedSearchFailed);
  }
  return failure == null;
}
