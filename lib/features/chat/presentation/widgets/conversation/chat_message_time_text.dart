import 'package:intl/intl.dart';

import 'package:tilomnov/l10n/l10n.dart';

/// When a message was sent, shown above it once tapped: "12:59 PM" today,
/// "Yesterday 12:59 PM", "Mon 12:59 PM" within the week, then the date.
String chatMessageTimeText(
  AppLocalizations l10n,
  String locale,
  DateTime sentAt, {
  DateTime? now,
}) {
  final at = sentAt.toLocal();
  final current = now ?? DateTime.now();
  final time = DateFormat.jm(locale).format(at);
  final daysAgo = _calendarDaysBetween(at, current);
  if (daysAgo <= 0) return time;
  if (daysAgo == 1) return l10n.chatMessageTimeYesterday(time);
  if (daysAgo < 7) return '${DateFormat.E(locale).format(at)} $time';
  final date = at.year == current.year
      ? DateFormat.MMMd(locale)
      : DateFormat.yMMMd(locale);
  return '${date.format(at)} $time';
}

/// When a message of the user's reached the server, shown below it once
/// tapped: "Delivered 5 minutes ago" for a day, then "Delivered Mon" within
/// the week, then "Delivered Oct 21".
String chatDeliveredText(
  AppLocalizations l10n,
  String locale,
  DateTime deliveredAt, {
  DateTime? now,
}) {
  final at = deliveredAt.toLocal();
  final current = now ?? DateTime.now();
  final ago = current.difference(at);
  if (ago.inMinutes < 1) return l10n.chatDeliveredJustNow;
  if (ago.inHours < 1) return l10n.chatDeliveredMinutes(ago.inMinutes);
  if (ago.inHours < 24) return l10n.chatDeliveredHours(ago.inHours);
  if (_calendarDaysBetween(at, current) < 7) {
    return l10n.chatDeliveredOn(DateFormat.E(locale).format(at));
  }
  final date = at.year == current.year
      ? DateFormat.MMMd(locale)
      : DateFormat.yMMMd(locale);
  return l10n.chatDeliveredOn(date.format(at));
}

/// Midnights between the days of [from] and [to], whatever their times.
int _calendarDaysBetween(DateTime from, DateTime to) {
  final fromDay = DateTime.utc(from.year, from.month, from.day);
  final toDay = DateTime.utc(to.year, to.month, to.day);
  return toDay.difference(fromDay).inDays;
}
