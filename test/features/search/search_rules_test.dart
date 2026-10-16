import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/data/models/search_area.dart';
import 'package:genie/features/search/data/models/search_results.dart';
import 'package:genie/features/search/data/search_results_cache.dart';
import 'package:genie/features/search/data/search_session_token.dart';
import 'package:genie/features/search/data/search_text.dart';
import 'package:genie/features/search/presentation/widgets/highlighted_text.dart';

PropertyModel _at(String id, double? lat, double? lng) => PropertyModel(
  id: id,
  title: id,
  price: '1',
  propertyType: 'Land',
  status: 'Active',
  createdAt: DateTime(2026),
  lat: lat,
  lng: lng,
);

void main() {
  group('SearchText', () {
    test('treats case, spacing and wildcards as the same text', () {
      expect(SearchText.normalize('  Veng   SRENG\t'), 'veng sreng');
      expect(SearchText.normalize('100%_deal'), '100 deal');
      expect(SearchText.normalize('a' * 200), hasLength(SearchText.maxLength));
    });

    test('needs two characters before it is worth a request', () {
      expect(SearchText.isSearchable(SearchText.normalize(' v ')), isFalse);
      expect(SearchText.isSearchable('ve'), isTrue);
    });
  });

  group('SearchResultsCache', () {
    test('forgets answers after their time to live', () {
      var now = DateTime(2026);
      final cache = SearchResultsCache(
        timeToLive: const Duration(minutes: 2),
        now: () => now,
      );
      cache.put('en:veng', SearchResults.empty);

      now = now.add(const Duration(minutes: 1));
      expect(cache.get('en:veng'), isNotNull);
      now = now.add(const Duration(minutes: 2));
      expect(cache.get('en:veng'), isNull);
    });

    test('drops the least recently used answer when full', () {
      final cache = SearchResultsCache(maxEntries: 2);
      cache.put('a', SearchResults.empty);
      cache.put('b', SearchResults.empty);
      cache.get('a'); // "b" is now the oldest use.
      cache.put('c', SearchResults.empty);

      expect(cache.get('a'), isNotNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), isNotNull);
    });
  });

  test('session tokens are distinct version-4 UUIDs the server accepts', () {
    final token = newSearchSessionToken();
    expect(
      token,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ),
      ),
    );
    expect(newSearchSessionToken(), isNot(token));
  });

  test('highlights every searched word, merging overlaps', () {
    expect(HighlightedText.matchRanges('Land near Veng Sreng', 'veng sreng'), [
      (10, 14),
      (15, 20),
    ]);
    expect(HighlightedText.matchRanges('aaaa', 'aa aaa'), [(0, 4)]);
    expect(HighlightedText.matchRanges('Villa', 'condo'), isEmpty);
  });

  test('a person\'s area frames every located listing', () {
    final area = SearchArea.around([
      _at('a', 11.5, 104.9),
      _at('b', 11.6, 104.8),
      _at('nowhere', null, null),
    ]);

    expect(area.properties, hasLength(3));
    expect(area.bounds!.southwest.latitude, 11.5);
    expect(area.bounds!.southwest.longitude, 104.8);
    expect(area.bounds!.northeast.latitude, 11.6);
    expect(area.bounds!.northeast.longitude, 104.9);
    expect(SearchArea.around([_at('nowhere', null, null)]).bounds, isNull);
  });
}
