import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/search/data/models/saved_search.dart';
import 'package:tilomnov/features/search/presentation/view_models/saved_searches_provider.dart';
import 'package:tilomnov/features/search/presentation/widgets/saved/saved_search_name_dialog.dart';
import 'package:tilomnov/features/search/presentation/widgets/saved/saved_search_summary.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/menus/app_menu_item.dart';

/// The searches the user saved from the map filter. Each can alert about
/// new listings, be renamed, deleted, or opened on the map again.
class SavedSearchesPage extends ConsumerWidget {
  const SavedSearchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final searches = ref.watch(savedSearchesProvider);

    return AppPageScaffold(
      title: l10n.savedSearchesTitle,
      child: RefreshIndicator(
        color: context.colors.accent,
        onRefresh: () => ref.refresh(savedSearchesProvider.future),
        child: searches.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => PageLoadFailure(
            error: error,
            message: l10n.savedSearchesLoadFailed,
            onRetry: () => ref.invalidate(savedSearchesProvider),
          ),
          data: (list) => list.isEmpty
              ? _Message(text: l10n.savedSearchesEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: context.colors.divider),
                  itemBuilder: (_, index) =>
                      _SavedSearchTile(search: list[index]),
                ),
        ),
      ),
    );
  }
}

enum _TileAction { rename, delete }

class _SavedSearchTile extends ConsumerWidget {
  final SavedSearch search;

  const _SavedSearchTile({required this.search});

  SavedSearchesNotifier _notifier(WidgetRef ref) =>
      ref.read(savedSearchesProvider.notifier);

  void _showOnMap(BuildContext context, WidgetRef ref) {
    ref.read(savedSearchToOpenProvider.notifier).state = search;
    Navigator.of(context).pop();
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showSavedSearchNameDialog(
      context,
      title: l10n.savedSearchRename,
      initialName: search.name,
    );
    if (name == null || name == search.name) return;
    final done = await _notifier(ref).rename(search, name);
    if (!done && context.mounted) {
      showFailure(context, fallback: l10n.savedSearchFailed);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final done = await _notifier(ref).delete(search);
    if (!context.mounted) return;
    if (done) {
      AppPopup.showSuccess(context, l10n.savedSearchDeleted);
    } else {
      showFailure(context, fallback: l10n.savedSearchFailed);
    }
  }

  Future<void> _setAlerts(BuildContext context, WidgetRef ref, bool on) async {
    final done = await _notifier(ref).setAlerts(search, on);
    if (!done && context.mounted) {
      showFailure(context, fallback: context.l10n.savedSearchFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;

    return ListTile(
      onTap: () => _showOnMap(context, ref),
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      leading: Icon(Icons.travel_explore, color: colors.accent),
      title: Text(
        search.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        savedSearchSummary(l10n, search.filter),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: l10n.savedSearchAlerts,
            child: Switch(
              value: search.alerts,
              onChanged: (on) => _setAlerts(context, ref, on),
            ),
          ),
          PopupMenuButton<_TileAction>(
            onSelected: (action) => switch (action) {
              _TileAction.rename => _rename(context, ref),
              _TileAction.delete => _delete(context, ref),
            },
            itemBuilder: (menuContext) => [
              appMenuItem(
                menuContext,
                value: _TileAction.rename,
                icon: Icons.edit_outlined,
                label: l10n.savedSearchRename,
              ),
              appMenuItem(
                menuContext,
                value: _TileAction.delete,
                icon: Icons.delete_outline,
                label: l10n.savedSearchDelete,
                danger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A short line in the middle of the page, scrollable so pulling refreshes.
class _Message extends StatelessWidget {
  final String text;

  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: context.colors.textMuted),
        ),
      ],
    );
  }
}
