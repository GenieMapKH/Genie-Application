import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/data/models/search_history_entry.dart';
import 'package:genie/features/search/presentation/screens/publisher_profile_page.dart';
import 'package:genie/features/search/presentation/search_layout.dart';
import 'package:genie/features/search/presentation/view_models/search_history_controller.dart';
import 'package:genie/features/search/presentation/widgets/search_history_list.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/features/search/presentation/view_models/search_query_controller.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';
import 'package:genie/features/search/presentation/widgets/search_input_bar.dart';
import 'package:genie/features/search/presentation/widgets/search_message_view.dart';
import 'package:genie/features/search/presentation/widgets/search_results_list.dart';
import 'package:genie/features/search/presentation/widgets/search_skeleton_list.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/transitions/app_page_route.dart';

/// Full-screen search: places, listings and people for what is typed.
/// Closes with the picked result as a [SearchSelection], or null.
class SearchPage extends ConsumerStatefulWidget {
  /// Places near this point are suggested first.
  final LatLng? near;

  /// Text to start from, e.g. the search the map is showing.
  final String initialText;

  const SearchPage({super.key, this.near, this.initialText = ''});

  static Route<SearchSelection> route({LatLng? near, String initialText = ''}) {
    return AppPageRoute<SearchSelection>(
      page: SearchPage(near: near, initialText: initialText),
      direction: SlideDirection.none,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialText,
  );
  final FocusNode _focus = FocusNode();
  bool _configured = false;
  late String _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;

    _language = Localizations.localeOf(context).languageCode == 'km'
        ? 'km'
        : 'en';
    final controller = ref.read(searchQueryControllerProvider.notifier);
    controller.configure(language: _language, near: widget.near);
    if (widget.initialText.isNotEmpty) {
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialText.length,
      );
      controller.onTextChanged(widget.initialText);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close([SearchSelection? selection]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(selection);
  }

  /// The keyboard's search key goes to the top place, as in a map app, once
  /// the answer for this exact text is on screen.
  void _submit(String raw) {
    final state = ref.read(searchQueryControllerProvider);
    final controller = ref.read(searchQueryControllerProvider.notifier);
    _remember();
    final answered = !state.isLoading && state.failure == null;
    if (answered && state.results.places.isNotEmpty) {
      _pickPlace(state.results.places.first.placeId);
      return;
    }
    controller.submit(raw);
  }

  /// Saves the typed text to the account's history: called when a search is
  /// finished (a result picked or the search key pressed), not per letter.
  void _remember() {
    ref.read(searchHistoryControllerProvider.notifier).record(_text.text);
  }

  /// Puts [text] in the field, with the cursor at its end.
  void _fill(String text) {
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Tapping a recent search runs it again straight away.
  void _searchAgain(SearchHistoryEntry entry) {
    _fill(entry.query);
    ref.read(searchQueryControllerProvider.notifier).submit(entry.query);
  }

  /// "Edit" puts it in the field to change before searching.
  void _editHistory(SearchHistoryEntry entry) {
    _fill(entry.query);
    _focus.requestFocus();
    ref.read(searchQueryControllerProvider.notifier).onTextChanged(entry.query);
  }

  Future<void> _removeHistory(SearchHistoryEntry entry) async {
    try {
      await ref.read(searchHistoryControllerProvider.notifier).remove(entry);
    } catch (error, stack) {
      AppLogger.error('Removing a search from history failed', error, stack);
      if (mounted) {
        AppPopup.showError(context, context.l10n.searchHistoryRemoveFailed);
      }
    }
  }

  /// A person or agency opens their profile over the results; back returns
  /// here, "View on map" closes search and shows their listings on the map.
  Future<void> _openProfile(PublisherSummary person) async {
    _remember();
    FocusScope.of(context).unfocus();
    final selection = await Navigator.of(
      context,
    ).push(PublisherProfilePage.route(person));
    if (selection != null && mounted) _close(selection);
  }

  void _pickPlace(String placeId) {
    _remember();
    final state = ref.read(searchQueryControllerProvider);
    final place = state.results.places.firstWhere((p) => p.placeId == placeId);
    _close(
      AreaSelection(
        PlaceTarget(
          place,
          sessionToken: ref
              .read(searchQueryControllerProvider.notifier)
              .sessionToken,
          language: _language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchQueryControllerProvider);
    final controller = ref.read(searchQueryControllerProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = SearchLayout.gutter(width);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SearchLayout.contentMaxWidth,
            ),
            child: Column(
              children: [
                SearchInputBar(
                  controller: _text,
                  focusNode: _focus,
                  isLoading: state.isLoading,
                  onChanged: controller.onTextChanged,
                  onSubmitted: _submit,
                  onBack: _close,
                ),
                Divider(height: 1, color: context.colors.divider),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _body(context, state, gutter),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SearchQueryState state, double gutter) {
    final l10n = context.l10n;
    final controller = ref.read(searchQueryControllerProvider.notifier);

    final history =
        ref.watch(searchHistoryControllerProvider).valueOrNull ?? const [];
    if (state.isIdle && history.isNotEmpty) {
      return SearchHistoryList(
        key: const ValueKey('history'),
        entries: history,
        gutter: gutter,
        onSearch: _searchAgain,
        onEdit: _editHistory,
        onRemove: _removeHistory,
      );
    }
    if (state.isIdle) {
      return Align(
        key: const ValueKey('idle'),
        alignment: const Alignment(0, -0.5),
        child: SearchMessageView(
          icon: Icons.travel_explore_rounded,
          title: l10n.searchIdleTitle,
          body: l10n.searchIdleBody,
        ),
      );
    }
    final failure = state.failure;
    if (failure != null) {
      return Align(
        key: const ValueKey('failure'),
        alignment: const Alignment(0, -0.5),
        child: SearchMessageView.failure(
          context,
          failure,
          onRetry: controller.retry,
        ),
      );
    }
    if (state.results.isEmpty) {
      if (state.isLoading) {
        return Align(
          key: const ValueKey('loading'),
          alignment: Alignment.topCenter,
          child: SearchSkeletonList(gutter: gutter),
        );
      }
      return Align(
        key: const ValueKey('empty'),
        alignment: const Alignment(0, -0.5),
        child: SearchMessageView(
          icon: Icons.search_off_rounded,
          title: l10n.searchNoResultsTitle(state.text),
          body: l10n.searchNoResultsBody,
        ),
      );
    }

    return SearchResultsList(
      key: const ValueKey('results'),
      results: state.results,
      query: state.text,
      gutter: gutter,
      onPlaceTap: (place) => _pickPlace(place.placeId),
      onPropertyTap: (property) {
        _remember();
        _close(PropertySelection(property));
      },
      onPersonTap: _openProfile,
    );
  }
}
