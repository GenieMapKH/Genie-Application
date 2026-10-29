import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';

void main() {
  group('ClosestSheetLayout', () {
    test('phones get a full-width sheet with one column', () {
      for (final width in [320.0, 360.0, 390.0, 430.0, 480.0]) {
        expect(ClosestSheetLayout.isDocked(width), isFalse, reason: '$width');
        expect(ClosestSheetLayout.width(width), width);
        expect(ClosestSheetLayout.columns(width), 1, reason: '$width');
      }
    });

    test('a narrow tablet held upright fits two columns', () {
      expect(ClosestSheetLayout.isDocked(700), isFalse);
      expect(ClosestSheetLayout.columns(700), 2);
      expect(
        ClosestSheetLayout.columnWidth(700),
        greaterThanOrEqualTo(ClosestSheetLayout.minColumnWidth),
      );
    });

    test('wide screens dock a panel at the left, one column wide', () {
      for (final width in [720.0, 844.0, 1024.0, 1366.0]) {
        expect(ClosestSheetLayout.isDocked(width), isTrue, reason: '$width');
        final panel = ClosestSheetLayout.width(width);
        expect(panel, inInclusiveRange(340, 420), reason: '$width');
        expect(ClosestSheetLayout.columns(panel), 1, reason: '$width');
      }
    });

    test('cards stay between a usable and a sensible height', () {
      double card(double width) =>
          ClosestSheetLayout.cardHeight(width, sheetHeight: 800);
      expect(card(200), 240);
      expect(card(400), closeTo(288, 0.01));
      expect(card(900), 340);
    });

    test('a short sheet shrinks the card so a whole one fits', () {
      final card = ClosestSheetLayout.cardHeight(340, sheetHeight: 284);
      expect(card, lessThan(284 * 0.7));
      expect(card, greaterThanOrEqualTo(180));
    });

    test('a release carries on in the direction the finger went', () {
      const stops = [0.05, 0.5, 1.0];
      double settle(double extent, {required bool up}) =>
          ClosestSheetLayout.settleExtent(extent, stops, movingUp: up);

      // Pulled up a fifth of the way or more: on to the next stop.
      expect(settle(0.20, up: true), 0.5);
      // Hardly moved: back where it was.
      expect(settle(0.08, up: true), 0.05);
      // Let down from the middle: only a fifth of the way commits it.
      expect(settle(0.42, up: false), 0.5);
      expect(settle(0.38, up: false), 0.05);
      // At a stop, or past the last: stays.
      expect(settle(0.5, up: true), 0.5);
      expect(settle(1.0, up: false), 1.0);
      // Two stops only (a short screen): the same between them.
      expect(
        ClosestSheetLayout.settleExtent(0.4, const [0.1, 1.0], movingUp: true),
        1.0,
      );
    });

    test('the middle stop leaves room for a card on short screens', () {
      expect(ClosestSheetLayout.middleExtent(800), 0.5);
      // A phone held sideways: the middle stop is most of the height.
      expect(ClosestSheetLayout.middleExtent(260), 1.0);
      expect(
        ClosestSheetLayout.peekExtent(600),
        closeTo(ClosestSheetLayout.peekHeight / 600, 0.001),
      );
    });
  });
}
