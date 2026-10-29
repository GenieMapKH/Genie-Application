import 'package:flutter/foundation.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';

/// What the map shows: the pills under the search bar and the filter page.
/// A null field or empty list means "any". The server applies the same rules
/// (`GET /public/properties/map`); [matches] repeats them on the device.
@immutable
class MapPropertyFilter {
  /// The listing types of the filter page's "For sale" tab.
  static const List<String> forSale = ['Sale'];

  /// The listing types of the filter page's "For rent" tab.
  static const List<String> forRent = ['Rent', 'To Let'];

  /// As stored, e.g. 'Business for Sale'.
  final String? propertyType;

  /// Any of these: 'Sale', 'Rent', 'To Let'.
  final List<String> listingTypes;

  /// USD, on the asking price (before any discount). Inclusive.
  final double? minPrice;
  final double? maxPrice;

  /// m², on the size a card shows ([PropertyModel.displaySize]). Inclusive.
  final double? minSize;
  final double? maxSize;

  /// Keyword codes the listing must all carry.
  final Set<String> keywords;

  const MapPropertyFilter({
    this.propertyType,
    this.listingTypes = const [],
    this.minPrice,
    this.maxPrice,
    this.minSize,
    this.maxSize,
    this.keywords = const {},
  });

  bool get isEmpty => this == const MapPropertyFilter();

  /// Set only on the filter page, so the pills can't show them.
  bool get hasPageOnlyFilters =>
      minPrice != null ||
      maxPrice != null ||
      minSize != null ||
      maxSize != null ||
      keywords.isNotEmpty;

  bool get isForRent =>
      listingTypes.isNotEmpty && listingTypes.every(forRent.contains);

  bool get isForSale => listingEquals(listingTypes, forSale);

  bool matches(PropertyModel property) =>
      (propertyType == null || property.propertyType == propertyType) &&
      (listingTypes.isEmpty || listingTypes.contains(property.listingType)) &&
      _inRange(property.askingPrice, minPrice, maxPrice) &&
      _sizeMatches(property.displaySize) &&
      keywords.every(property.keywords.contains);

  bool _sizeMatches(double? size) {
    if (minSize == null && maxSize == null) return true;
    return size != null && _inRange(size, minSize, maxSize);
  }

  static bool _inRange(double value, double? min, double? max) =>
      (min == null || value >= min) && (max == null || value <= max);

  /// The query parameters the map endpoints take for this filter.
  Map<String, Object> toQueryParameters() => {
    'propertyType': ?propertyType,
    if (listingTypes.isNotEmpty) 'listingType': listingTypes,
    'minPrice': ?minPrice,
    'maxPrice': ?maxPrice,
    'minSize': ?minSize,
    'maxSize': ?maxSize,
    if (keywords.isNotEmpty) 'keyword': (keywords.toList()..sort()),
  };

  /// Picking the selected value again clears it.
  MapPropertyFilter toggleType(String type) =>
      _copy(propertyType: () => propertyType == type ? null : type);

  /// The pill picks one listing type; picking it again clears it.
  MapPropertyFilter toggleListing(String listing) => _copy(
    listingTypes: listingEquals(listingTypes, [listing]) ? const [] : [listing],
  );

  MapPropertyFilter toggleKeyword(String code) => _copy(
    keywords: keywords.contains(code)
        ? ({...keywords}..remove(code))
        : {...keywords, code},
  );

  MapPropertyFilter withListingTypes(List<String> types) =>
      _copy(listingTypes: types);

  MapPropertyFilter withPrice(double? min, double? max) =>
      _copy(minPrice: () => min, maxPrice: () => max);

  MapPropertyFilter withSize(double? min, double? max) =>
      _copy(minSize: () => min, maxSize: () => max);

  MapPropertyFilter _copy({
    String? Function()? propertyType,
    List<String>? listingTypes,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    double? Function()? minSize,
    double? Function()? maxSize,
    Set<String>? keywords,
  }) => MapPropertyFilter(
    propertyType: propertyType != null ? propertyType() : this.propertyType,
    listingTypes: listingTypes ?? this.listingTypes,
    minPrice: minPrice != null ? minPrice() : this.minPrice,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    minSize: minSize != null ? minSize() : this.minSize,
    maxSize: maxSize != null ? maxSize() : this.maxSize,
    keywords: keywords ?? this.keywords,
  );

  static bool listingEquals(List<String> a, List<String> b) =>
      setEquals(a.toSet(), b.toSet());

  @override
  bool operator ==(Object other) =>
      other is MapPropertyFilter &&
      other.propertyType == propertyType &&
      listingEquals(other.listingTypes, listingTypes) &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.minSize == minSize &&
      other.maxSize == maxSize &&
      setEquals(other.keywords, keywords);

  @override
  int get hashCode => Object.hash(
    propertyType,
    Object.hashAllUnordered(listingTypes),
    minPrice,
    maxPrice,
    minSize,
    maxSize,
    Object.hashAllUnordered(keywords),
  );
}
