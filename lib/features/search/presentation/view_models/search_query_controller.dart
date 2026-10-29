import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/search/data/models/search_results.dart';
import 'package:tilomnov/features/search/data/search_failure.dart';
import 'package:tilomnov/features/search/data/search_session_token.dart';
import 'package:tilomnov/features/search/data/search_text.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_providers.dart';

/// What the search page shows for the text being typed.
class SearchQueryState {
  /// The normalized text; [results] answer it once [isLoading] is false.
  final String text;

  /// Kept on screen while the next text loads, so the list does not flash.
  final SearchResults results;
  final bool isLoading;
  final SearchFailureReason? failure;

  const SearchQueryState({
    this.text = '',
    this.results = SearchResults.empty,
    this.isLoading = false,
    this.failure,
  });

  /// Nothing worth searching for has been typed yet.
  bool get isIdle => !SearchText.isSearchable(text);
}

/// Turns typing into as few requests as possible:
/// - waits for a [debounce] pause in typing before asking the server;
/// - never asks for a text shorter than [SearchText.minLength], or for the
///   same text twice in a row (case and spacing do not count);
/// - answers recently searched texts from memory, without a request;
/// - cancels a request whose text has already changed.
class SearchQueryController extends AutoDisposeNotifier<SearchQueryState> {
  /// How long typing must pause before the text is sent.
  static const debounce = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  CancelToken? _inFlight;
  LatLng? _near;
  String _language = 'en';

  /// One per page visit: the suggestions and the place finally picked are
  /// billed by the map provider as one session.
  final String sessionToken = newSearchSessionToken();

  @override
  SearchQueryState build() {
    ref.onDispose(_cancelPending);
    return const SearchQueryState();
  }

  /// [near] ranks places close to the map's centre first.
  void configure({required String language, LatLng? near}) {
    _language = language;
    _near = near;
  }

  void onTextChanged(String raw) {
    final text = SearchText.normalize(raw);
    if (text == state.text && state.failure == null) return;

    _cancelPending();
    if (!SearchText.isSearchable(text)) {
      state = SearchQueryState(text: text);
      return;
    }

    final cached = ref.read(searchRepositoryProvider).cached(text, _language);
    if (cached != null) {
      state = SearchQueryState(text: text, results: cached);
      return;
    }

    state = SearchQueryState(
      text: text,
      results: state.results,
      isLoading: true,
    );
    _debounceTimer = Timer(debounce, () => _run(text));
  }

  /// The keyboard's search key: no need to wait for the pause.
  void submit(String raw) {
    final text = SearchText.normalize(raw);
    if (!SearchText.isSearchable(text)) return;
    final alreadyAnswered =
        text == state.text && !state.isLoading && state.failure == null;
    if (alreadyAnswered) return;

    _cancelPending();
    state = SearchQueryState(
      text: text,
      results: state.results,
      isLoading: true,
    );
    _run(text);
  }

  void retry() => submit(state.text);

  Future<void> _run(String text) async {
    final cancelToken = _inFlight = CancelToken();
    try {
      final results = await ref
          .read(searchRepositoryProvider)
          .search(
            text,
            language: _language,
            sessionToken: sessionToken,
            near: _near,
            cancelToken: cancelToken,
          );
      if (cancelToken.isCancelled) return;
      state = SearchQueryState(text: text, results: results);
    } on SearchFailure catch (failure) {
      if (cancelToken.isCancelled) return;
      state = SearchQueryState(text: text, failure: failure.reason);
    } on DioException catch (error) {
      // Only a cancelled request ends up here: a newer text replaced it.
      if (!CancelToken.isCancel(error)) rethrow;
    }
  }

  void _cancelPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _inFlight?.cancel();
    _inFlight = null;
  }
}

final searchQueryControllerProvider =
    AutoDisposeNotifierProvider<SearchQueryController, SearchQueryState>(
      SearchQueryController.new,
    );
