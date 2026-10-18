import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/search/data/models/search_history_entry.dart';
import 'package:genie/features/search/presentation/widgets/results/search_section_header.dart';
import 'package:genie/l10n/l10n.dart';

/// "Recent searches", shown while nothing is typed. Tapping a row searches
/// it again; each row can also be edited first, or removed.
class SearchHistoryList extends StatelessWidget {
  final List<SearchHistoryEntry> entries;
  final double gutter;
  final ValueChanged<SearchHistoryEntry> onSearch;
  final ValueChanged<SearchHistoryEntry> onEdit;
  final ValueChanged<SearchHistoryEntry> onRemove;

  const SearchHistoryList({
    super.key,
    required this.entries,
    required this.gutter,
    required this.onSearch,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: SearchSectionHeader(
            title: context.l10n.searchRecentTitle,
            gutter: gutter,
          ),
        ),
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _HistoryTile(
              // Keyed by text: a removed row's buttons never act on its
              // neighbour as the list closes up.
              key: ValueKey(entry.query),
              entry: entry,
              gutter: gutter,
              onSearch: () => onSearch(entry),
              onEdit: () => onEdit(entry),
              onRemove: () => onRemove(entry),
            );
          },
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SearchHistoryEntry entry;
  final double gutter;
  final VoidCallback onSearch;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _HistoryTile({
    super.key,
    required this.entry,
    required this.gutter,
    required this.onSearch,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return InkWell(
      onTap: onSearch,
      child: Padding(
        padding: EdgeInsets.only(left: gutter, right: gutter - 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 20,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  entry.query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onEdit,
              tooltip: l10n.searchHistoryEdit,
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: colors.textMuted,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: l10n.searchHistoryRemove,
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
