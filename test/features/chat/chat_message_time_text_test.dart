import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_message_time_text.dart';
import 'package:tilomnov/l10n/l10n.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  // The app loads these through its localization delegates.
  setUpAll(() => initializeDateFormatting('en'));

  // A Wednesday afternoon.
  final now = DateTime(2026, 10, 28, 15, 30);

  group('chatMessageTimeText', () {
    // intl puts a narrow no-break space before AM and PM.
    String timeOf(DateTime sentAt) =>
        chatMessageTimeText(_en, 'en', sentAt, now: now).replaceAll(' ', ' ');

    test('today: the time only', () {
      expect(timeOf(DateTime(2026, 10, 28, 12, 59)), '12:59 PM');
    });

    test('yesterday, even less than a day ago', () {
      expect(timeOf(DateTime(2026, 10, 27, 23, 10)), 'Yesterday 11:10 PM');
    });

    test('within the week: the weekday', () {
      expect(timeOf(DateTime(2026, 10, 26, 9, 5)), 'Mon 9:05 AM');
    });

    test('earlier this year: the date', () {
      expect(timeOf(DateTime(2026, 10, 1, 9, 5)), 'Oct 1 9:05 AM');
    });

    test('an earlier year: the date with the year', () {
      expect(timeOf(DateTime(2025, 10, 1, 9, 5)), 'Oct 1, 2025 9:05 AM');
    });
  });

  group('chatDeliveredText', () {
    String delivered(Duration ago) =>
        chatDeliveredText(_en, 'en', now.subtract(ago), now: now);

    test('just now', () {
      expect(delivered(const Duration(seconds: 20)), 'Delivered just now');
    });

    test('minutes and hours ago, for a day', () {
      expect(delivered(const Duration(minutes: 1)), 'Delivered 1 minute ago');
      expect(
        delivered(const Duration(minutes: 45)),
        'Delivered 45 minutes ago',
      );
      expect(delivered(const Duration(hours: 1)), 'Delivered 1 hour ago');
      expect(
        delivered(const Duration(hours: 23, minutes: 59)),
        'Delivered 23 hours ago',
      );
    });

    test('after a day: the weekday', () {
      expect(delivered(const Duration(hours: 24)), 'Delivered Tue');
      expect(delivered(const Duration(days: 6)), 'Delivered Thu');
    });

    test('after a week: the date', () {
      expect(delivered(const Duration(days: 8)), 'Delivered Oct 20');
    });
  });
}
