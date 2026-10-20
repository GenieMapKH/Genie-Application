import 'package:genie/core/logging/app_logger.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'nearby_place.dart';
import 'property_details.dart';

class PropertyModel {
  final String id;
  final String title;
  final String price;
  final String propertyType;

  /// 'Sale', 'Rent' or 'To Let'; null for listings saved before it was asked.
  final String? listingType;

  /// 'percent' or 'amount' (USD off [price]); null without a discount.
  final String? discountType;
  final double? discountValue;
  final String status; // 'Active', 'Draft', 'Pending', 'Sold'
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<LatLng> boundaryPoints;
  final String? description;
  final int? bedrooms;
  final int? bathrooms;
  final double? landSize;
  final double? buildingSize;
  final double? unitSize;

  /// Feature codes, see `PropertyKeyword`.
  final List<String> keywords;
  final PropertyDetails details;

  /// Markets, hospitals and schools near the listing, closest first within
  /// each category. Only in a full listing (not the map's list).
  final List<NearbyPlace> nearbyPlaces;

  /// When [nearbyPlaces] were looked up; null if never, so an empty list
  /// then means "not looked up" rather than "nothing nearby".
  final DateTime? nearbySearchedAt;
  final double? lat;
  final double? lng;
  final String? ownerId;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? ownerEmail;
  final String? ownerPhone;

  /// People who saved the listing.
  final int saveCount;

  /// People other than the owner who opened the listing, each counted once.
  final int viewCount;
  final int contactCount;
  final bool isVisited;

  PropertyModel({
    required this.id,
    required this.title,
    required this.price,
    required this.propertyType,
    this.listingType,
    this.discountType,
    this.discountValue,
    required this.status,
    required this.createdAt,
    this.imageUrls = const [],
    this.boundaryPoints = const [],
    this.description,
    this.bedrooms,
    this.bathrooms,
    this.landSize,
    this.buildingSize,
    this.unitSize,
    this.keywords = const [],
    this.details = const PropertyDetails(),
    this.nearbyPlaces = const [],
    this.nearbySearchedAt,
    this.lat,
    this.lng,
    this.ownerId,
    this.ownerName,
    this.ownerAvatarUrl,
    this.ownerEmail,
    this.ownerPhone,
    this.saveCount = 0,
    this.viewCount = 0,
    this.contactCount = 0,
    this.isVisited = false,
  });

  /// Hours elapsed since the listing was published.
  int get hoursListed => DateTime.now().difference(createdAt).inHours;

  /// Days elapsed since the listing was published.
  int get daysListed => DateTime.now().difference(createdAt).inDays;

  /// Listings younger than 12 hours get the "New" badge on the map.
  bool get isNew => hoursListed <= 12;

  bool get hasDiscount => discountType != null && discountValue != null;

  /// The price before any discount.
  double get askingPrice => double.tryParse(price) ?? 0;

  /// What a buyer pays: the asking price less the discount.
  double get finalPrice {
    if (!hasDiscount) return askingPrice;
    final off = discountType == 'percent'
        ? askingPrice * discountValue! / 100
        : discountValue!;
    return askingPrice - off;
  }

  /// Formatted (discounted) price for map markers (e.g. 10000 -> 10K, 1500000 -> 1.5M)
  String get formattedPrice {
    final double val = finalPrice;
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    }
    return val.toStringAsFixed(0);
  }

  /// The size shown on cards: land properties report land size, built
  /// properties report the unit or building footprint.
  double? get displaySize {
    if (landSize != null && landSize! > 0) return landSize;
    if (unitSize != null && unitSize! > 0) return unitSize;
    if (buildingSize != null && buildingSize! > 0) return buildingSize;
    return null;
  }

  /// A list of listings as the server sends it. Static, so a large list can
  /// be parsed off the UI thread with `compute`.
  static List<PropertyModel> listFromJson(List<dynamic> data) => [
    for (final json in data) PropertyModel.fromJson(json),
  ];

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    List<LatLng> points = [];
    try {
      if (json['boundaryPoints'] != null) {
        var bp = json['boundaryPoints'];
        if (bp is String) {
          bp = jsonDecode(bp);
        }
        if (bp is List) {
          points = bp
              .map(
                (p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      AppLogger.debug('Error parsing boundaryPoints: $e');
    }

    List<String> images = [];
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List)
          .map((img) {
            if (img is Map) {
              return (img['url'] ??
                      img['path'] ??
                      img['imageUrl'] ??
                      img['src'] ??
                      '')
                  .toString();
            } else if (img != null) {
              return img.toString();
            }
            return '';
          })
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['imageUrls'] != null && json['imageUrls'] is List) {
      images = (json['imageUrls'] as List)
          .map((e) => e?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['photos'] != null && json['photos'] is List) {
      images = (json['photos'] as List)
          .map(
            (e) =>
                (e is Map ? (e['url'] ?? e['path'] ?? '') : e)?.toString() ??
                '',
          )
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['image'] != null &&
        json['image'] is String &&
        (json['image'] as String).isNotEmpty) {
      images = [json['image'] as String];
    }

    final counts = json['_count'];
    final owner = json['user'];

    return PropertyModel(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      price: json['price']?.toString() ?? '0',
      propertyType: json['propertyType'] ?? 'Land',
      listingType: json['listingType'] as String?,
      discountType: json['discountType'] as String?,
      discountValue: json['discountValue'] == null
          ? null
          : double.tryParse(json['discountValue'].toString()),
      status: json['status'] ?? 'Draft',
      createdAt: DateTime.parse(json['createdAt']),
      imageUrls: images,
      boundaryPoints: points,
      description: json['description'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      landSize: json['landSize'] != null
          ? double.tryParse(json['landSize'].toString())
          : null,
      buildingSize: json['buildingSize'] != null
          ? double.tryParse(json['buildingSize'].toString())
          : null,
      unitSize: json['unitSize'] != null
          ? double.tryParse(json['unitSize'].toString())
          : null,
      keywords: _keywordCodes(json['keywords']),
      details: PropertyDetails.fromJson(json),
      nearbyPlaces: [
        if (json['nearbyPlaces'] is List)
          for (final place in json['nearbyPlaces'] as List)
            NearbyPlace.fromJson(place as Map<String, dynamic>),
      ],
      nearbySearchedAt: json['nearbySearchedAt'] == null
          ? null
          : DateTime.tryParse(json['nearbySearchedAt'] as String),
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      ownerId: owner is Map ? owner['id'] as String? : null,
      ownerName: owner is Map
          ? (owner['name'] as String? ??
                owner['username'] as String? ??
                owner['email'] as String? ??
                owner['phone'] as String?)
          : null,
      ownerAvatarUrl: owner is Map ? owner['avatarUrl'] as String? : null,
      ownerEmail: owner is Map ? owner['email'] as String? : null,
      ownerPhone: owner is Map ? owner['phone'] as String? : null,
      saveCount: counts is Map ? (counts['favorites'] as int? ?? 0) : 0,
      viewCount: counts is Map ? (counts['views'] as int? ?? 0) : 0,
      contactCount: counts is Map ? (counts['contacts'] as int? ?? 0) : 0,
      isVisited: json['isVisited'] == true,
    );
  }

  /// The server sends `[{keyword: 'road_access'}, ...]`.
  static List<String> _keywordCodes(Object? keywords) {
    if (keywords is! List) return const [];
    return [
      for (final entry in keywords)
        if (entry is Map && entry['keyword'] is String)
          entry['keyword'] as String
        else if (entry is String)
          entry,
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': double.tryParse(price) ?? 0,
      'propertyType': propertyType,
      if (description != null) 'description': description,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (landSize != null) 'landSize': landSize,
      if (unitSize != null) 'unitSize': unitSize,
    };
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? price,
    String? propertyType,
    String? listingType,
    String? discountType,
    double? discountValue,
    String? status,
    DateTime? createdAt,
    List<String>? imageUrls,
    List<LatLng>? boundaryPoints,
    String? description,
    int? bedrooms,
    int? bathrooms,
    double? landSize,
    double? buildingSize,
    double? unitSize,
    List<String>? keywords,
    PropertyDetails? details,
    List<NearbyPlace>? nearbyPlaces,
    DateTime? nearbySearchedAt,
    double? lat,
    double? lng,
    String? ownerId,
    String? ownerName,
    String? ownerAvatarUrl,
    String? ownerEmail,
    String? ownerPhone,
    int? saveCount,
    int? viewCount,
    int? contactCount,
    bool? isVisited,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      boundaryPoints: boundaryPoints ?? this.boundaryPoints,
      description: description ?? this.description,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      landSize: landSize ?? this.landSize,
      buildingSize: buildingSize ?? this.buildingSize,
      unitSize: unitSize ?? this.unitSize,
      keywords: keywords ?? this.keywords,
      details: details ?? this.details,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      nearbySearchedAt: nearbySearchedAt ?? this.nearbySearchedAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      saveCount: saveCount ?? this.saveCount,
      viewCount: viewCount ?? this.viewCount,
      contactCount: contactCount ?? this.contactCount,
      isVisited: isVisited ?? this.isVisited,
    );
  }
}
