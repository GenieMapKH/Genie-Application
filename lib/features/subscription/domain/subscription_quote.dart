/// The server's price for this checkout, valid for five minutes.
class SubscriptionQuote {
  final String token;
  final double amount;
  final DateTime periodEnd;
  final bool isUpgrade;
  final String billingPeriod;

  const SubscriptionQuote({
    required this.token,
    required this.amount,
    required this.periodEnd,
    required this.isUpgrade,
    this.billingPeriod = 'monthly',
  });

  factory SubscriptionQuote.fromJson(Map<String, dynamic> json) =>
      SubscriptionQuote(
        token: json['quote'] as String,
        amount: (json['amount'] as num).toDouble(),
        periodEnd: DateTime.parse(json['periodEnd'] as String),
        isUpgrade: json['isUpgrade'] == true,
        billingPeriod: json['billingPeriod'] as String? ?? 'monthly',
      );
}
