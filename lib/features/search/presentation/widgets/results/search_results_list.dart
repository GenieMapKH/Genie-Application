import 'package:flutter/material.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/data/models/place_suggestion.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/data/models/search_results.dart';
import 'package:genie/features/search/presentation/widgets/results/person_result_tile.dart';
import 'package:genie/features/search/presentation/widgets/results/place_result_tile.dart';
import 'package:genie/features/search/presentation/widgets/results/property_result_tile.dart';
import 'package:genie/features/search/presentation/widgets/results/search_section_header.dart';
import 'package:genie/l10n/l10n.dart';

/// The three groups of results, places first as in a map app. Built lazily:
/// only rows on screen are laid out.
class SearchResultsList extends StatelessWidget {
  final SearchResults results;
  final String query;
  final double gutter;
  final ValueChanged<PlaceSuggestion> onPlaceTap;
  final ValueChanged<PropertyModel> onPropertyTap;
  final ValueChanged<PublisherSummary> onPersonTap;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.query,
    required this.gutter,
    required this.onPlaceTap,
    required this.onPropertyTap,
    required this.onPersonTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        ..._section(
          title: l10n.searchSectionPlaces,
          items: results.places,
          build: (place) => PlaceResultTile(
            place: place,
            query: query,
            gutter: gutter,
            onTap: () => onPlaceTap(place),
          ),
        ),
        ..._section(
          title: l10n.searchSectionListings,
          items: results.properties,
          build: (property) => PropertyResultTile(
            property: property,
            query: query,
            gutter: gutter,
            onTap: () => onPropertyTap(property),
          ),
        ),
        ..._section(
          title: l10n.searchSectionPeople,
          items: results.people,
          build: (person) => PersonResultTile(
            person: person,
            query: query,
            gutter: gutter,
            onTap: () => onPersonTap(person),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
        ),
      ],
    );
  }

  List<Widget> _section<T>({
    required String title,
    required List<T> items,
    required Widget Function(T item) build,
  }) {
    if (items.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: SearchSectionHeader(title: title, gutter: gutter),
      ),
      SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => build(items[index]),
      ),
    ];
  }
}
