/// How a buyer reached an owner from a listing: what counts as a lead.
enum LeadChannel { call, chat }

/// What one day added: new viewers, new saves, new leads (Cambodia time).
class InsightDay {
  final DateTime date;
  final int views;
  final int saves;
  final int leads;

  const InsightDay({
    required this.date,
    required this.views,
    required this.saves,
    required this.leads,
  });

  factory InsightDay.fromJson(Map<String, dynamic> json) {
    return InsightDay(
      date: DateTime.parse(json['date'] as String),
      views: (json['views'] as num).toInt(),
      saves: (json['saves'] as num).toInt(),
      leads: (json['leads'] as num).toInt(),
    );
  }
}

/// Which daily count the chart shows.
enum InsightMeasure { views, saves, leads }

extension InsightDayMeasure on InsightDay {
  int valueOf(InsightMeasure measure) => switch (measure) {
    InsightMeasure.views => views,
    InsightMeasure.saves => saves,
    InsightMeasure.leads => leads,
  };
}

/// How the owner's listing is doing (`GET /properties/:id/insights`). Each
/// person counts once per kind.
class PropertyInsights {
  final int views;
  final int saves;
  final int calls;
  final int chats;

  /// The last 14 days, oldest first, today last.
  final List<InsightDay> days;

  const PropertyInsights({
    required this.views,
    required this.saves,
    required this.calls,
    required this.chats,
    required this.days,
  });

  factory PropertyInsights.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    int count(String key) => (totals[key] as num).toInt();
    return PropertyInsights(
      views: count('views'),
      saves: count('saves'),
      calls: count('calls'),
      chats: count('chats'),
      days: (json['days'] as List)
          .map((day) => InsightDay.fromJson(day as Map<String, dynamic>))
          .toList(),
    );
  }

  /// [measure] over the last 7 days, and over the 7 before them.
  ({int thisWeek, int lastWeek}) weekOf(InsightMeasure measure) {
    int sum(Iterable<InsightDay> days) =>
        days.fold(0, (total, day) => total + day.valueOf(measure));
    final recent = days.length > 7 ? days.sublist(days.length - 7) : days;
    final before = days.length > 7
        ? days.sublist(0, days.length - 7)
        : const <InsightDay>[];
    return (thisWeek: sum(recent), lastWeek: sum(before));
  }

  bool get isEmpty => views == 0 && saves == 0 && calls == 0 && chats == 0;
}
