class AdminIncomeDay {
  final DateTime date;
  final double subscriptionUsd;
  final double listingUsd;
  const AdminIncomeDay({
    required this.date,
    required this.subscriptionUsd,
    required this.listingUsd,
  });
  double get totalUsd => subscriptionUsd + listingUsd;

  factory AdminIncomeDay.fromJson(Map<String, dynamic> json) => AdminIncomeDay(
    date: DateTime.parse(json['date'] as String),
    subscriptionUsd: (json['subscriptionUsd'] as num).toDouble(),
    listingUsd: (json['listingUsd'] as num).toDouble(),
  );
}

class AdminIncome {
  final double subscriptionUsd;
  final double listingUsd;
  final List<AdminIncomeDay> days;
  const AdminIncome({
    required this.subscriptionUsd,
    required this.listingUsd,
    required this.days,
  });

  factory AdminIncome.fromJson(Map<String, dynamic> json) => AdminIncome(
    subscriptionUsd: (json['subscriptionUsd'] as num).toDouble(),
    listingUsd: (json['listingUsd'] as num).toDouble(),
    days: (json['days'] as List)
        .map((day) => AdminIncomeDay.fromJson(day as Map<String, dynamic>))
        .toList(),
  );
}
