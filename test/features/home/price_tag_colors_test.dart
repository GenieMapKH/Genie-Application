import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/utils/map/markers/property_markers.dart';

Color _tag(String listingType, {bool isVisited = false}) =>
    PropertyMarkers.priceTagLayout(
      price: r'$1,000',
      listingType: listingType,
      isVisited: isVisited,
    ).background;

void main() {
  test('a listing for sale is green, dimmed once visited', () {
    expect(_tag('Sale'), PropertyMarkers.green);
    expect(_tag('Sale', isVisited: true), const Color(0xFF6AE0B1));
  });

  test('a listing for rent is red, pink once visited', () {
    expect(_tag('Rent'), const Color(0xFFE5484D));
    expect(_tag('Rent', isVisited: true), const Color(0xFFEFB6B8));
  });

  test('a listing to let is yellow, pale once visited', () {
    expect(_tag('To Let'), const Color(0xFFDBA122));
    expect(_tag('To Let', isVisited: true), const Color(0xFFEFDDB5));
  });
}
