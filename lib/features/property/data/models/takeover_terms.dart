const takeoverListingType = 'Takeover Payments';
const takeoverProviders = ['Developer', 'Bank'];
const takeoverFrequencies = ['Monthly', 'Quarterly', 'Yearly'];
const takeoverInterestTypes = ['None', 'Fixed', 'Variable', 'Unknown'];
const takeoverTransferStatuses = [
  'Not checked',
  'Conditional',
  'Written approval',
  'Not allowed',
];
const takeoverCostPayers = ['Buyer', 'Seller', 'Shared', 'Unknown'];

class TakeoverPayment {
  final double? amount;
  final String? dueDate;
  const TakeoverPayment({this.amount, this.dueDate});

  Map<String, dynamic> toJson() => {'amount': amount, 'dueDate': dueDate};
}

/// Seller-reported terms. Larger payments are part of the balance, not added twice.
class TakeoverTerms {
  final String? providerType;
  final String? providerName;
  final String? projectName;
  final double? sellerAmount;
  final double? remainingBalance;
  final String? balanceAsOf;
  final double? paymentAmount;
  final String? paymentFrequency;
  final int? remainingMonths;
  final String? nextPaymentDate;
  final String? interestType;
  final double? annualInterestRate;
  final String? transferStatus;
  final double? transferFee;
  final String? transferFeePayer;
  final double? arrearsAmount;
  final String? arrearsPayer;
  final String? notes;
  final bool? hasAdditionalPayments;
  final List<TakeoverPayment> additionalPayments;

  const TakeoverTerms({
    this.providerType,
    this.providerName,
    this.projectName,
    this.sellerAmount,
    this.remainingBalance,
    this.balanceAsOf,
    this.paymentAmount,
    this.paymentFrequency,
    this.remainingMonths,
    this.nextPaymentDate,
    this.interestType,
    this.annualInterestRate,
    this.transferStatus,
    this.transferFee,
    this.transferFeePayer,
    this.arrearsAmount,
    this.arrearsPayer,
    this.notes,
    this.hasAdditionalPayments,
    this.additionalPayments = const [],
  });

  double? get combinedPrice =>
      sellerAmount == null ||
          remainingBalance == null ||
          !sellerAmount!.isFinite ||
          !remainingBalance!.isFinite
      ? null
      : ((sellerAmount! * 100).round() + (remainingBalance! * 100).round()) /
            100;

  factory TakeoverTerms.fromJson(Map<String, dynamic> json) {
    String? text(String key) => json[key]?.toString().trim();
    double? number(String key) => double.tryParse(json[key]?.toString() ?? '');
    String? date(String key) => text(key)?.split('T').first;
    return TakeoverTerms(
      providerType: text('providerType'),
      providerName: text('providerName'),
      projectName: text('projectName'),
      sellerAmount: number('sellerAmount'),
      remainingBalance: number('remainingBalance'),
      balanceAsOf: date('balanceAsOf'),
      paymentAmount: number('paymentAmount'),
      paymentFrequency: text('paymentFrequency'),
      remainingMonths: int.tryParse(json['remainingMonths']?.toString() ?? ''),
      nextPaymentDate: date('nextPaymentDate'),
      interestType: text('interestType'),
      annualInterestRate: number('annualInterestRate'),
      transferStatus: text('transferStatus'),
      transferFee: number('transferFee'),
      transferFeePayer: text('transferFeePayer'),
      arrearsAmount: number('arrearsAmount'),
      arrearsPayer: text('arrearsPayer'),
      notes: text('notes'),
      hasAdditionalPayments: json['hasAdditionalPayments'] as bool?,
      additionalPayments: [
        for (final payment in json['additionalPayments'] as List? ?? const [])
          TakeoverPayment(
            amount: double.tryParse(payment['amount']?.toString() ?? ''),
            dueDate: payment['dueDate']?.toString().split('T').first,
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'providerType': providerType,
    'providerName': providerName,
    'projectName': projectName,
    'sellerAmount': sellerAmount,
    'remainingBalance': remainingBalance,
    'balanceAsOf': balanceAsOf,
    'paymentAmount': paymentAmount,
    'paymentFrequency': paymentFrequency,
    'remainingMonths': remainingMonths,
    'nextPaymentDate': nextPaymentDate,
    'interestType': interestType,
    'annualInterestRate': annualInterestRate,
    'transferStatus': transferStatus,
    'transferFee': transferFee,
    'transferFeePayer': transferFeePayer,
    'arrearsAmount': arrearsAmount,
    'arrearsPayer': arrearsPayer,
    'notes': notes,
    'hasAdditionalPayments': hasAdditionalPayments,
    'additionalPayments': additionalPayments.map((p) => p.toJson()).toList(),
  };

  /// Field names with missing or invalid values; shared by the form and submit.
  Set<String> get errors {
    final result = <String>{};
    final json = toJson();
    for (final key in [
      'providerType',
      'providerName',
      'sellerAmount',
      'remainingBalance',
      'balanceAsOf',
      'paymentAmount',
      'paymentFrequency',
      'remainingMonths',
      'nextPaymentDate',
      'interestType',
      'transferStatus',
      'transferFeePayer',
      'arrearsAmount',
      'hasAdditionalPayments',
    ]) {
      if (json[key] == null || json[key].toString().trim().isEmpty) {
        result.add(key);
      }
    }
    if (!takeoverProviders.contains(providerType)) result.add('providerType');
    if (!takeoverFrequencies.contains(paymentFrequency)) {
      result.add('paymentFrequency');
    }
    if (!takeoverInterestTypes.contains(interestType)) {
      result.add('interestType');
    }
    if (!takeoverTransferStatuses.contains(transferStatus) ||
        transferStatus == 'Not allowed') {
      result.add('transferStatus');
    }
    if (!takeoverCostPayers.contains(transferFeePayer)) {
      result.add('transferFeePayer');
    }
    if (providerType == 'Developer' && (projectName?.isEmpty ?? true)) {
      result.add('projectName');
    }
    for (final key in [
      'sellerAmount',
      'remainingBalance',
      'paymentAmount',
      'transferFee',
      'arrearsAmount',
    ]) {
      final value = json[key] as double?;
      if (value != null && !validMoney(value)) result.add(key);
    }
    if (remainingBalance != null && remainingBalance! <= 0) {
      result.add('remainingBalance');
    }
    if (paymentAmount != null && paymentAmount! <= 0) {
      result.add('paymentAmount');
    }
    if (remainingMonths != null &&
        (remainingMonths! < 1 || remainingMonths! > 1200)) {
      result.add('remainingMonths');
    }
    for (final key in ['balanceAsOf', 'nextPaymentDate']) {
      if (!validDate(json[key] as String?)) result.add(key);
    }
    if (['Fixed', 'Variable'].contains(interestType) &&
        annualInterestRate == null) {
      result.add('annualInterestRate');
    }
    if (annualInterestRate != null &&
        (!validMoney(annualInterestRate!) || annualInterestRate! > 100)) {
      result.add('annualInterestRate');
    }
    if (interestType == 'None' && (annualInterestRate ?? 0) != 0) {
      result.add('annualInterestRate');
    }
    if ((arrearsAmount ?? 0) > 0 &&
        !takeoverCostPayers.contains(arrearsPayer)) {
      result.add('arrearsPayer');
    }
    if ((arrearsAmount ?? 0) > 0 && (notes?.trim().isEmpty ?? true)) {
      result.add('notes');
    }
    if (hasAdditionalPayments == true && additionalPayments.isEmpty) {
      result.add('additionalPayments');
    }
    if (hasAdditionalPayments == false && additionalPayments.isNotEmpty) {
      result.add('additionalPayments');
    }
    if (additionalPayments.length > 24 ||
        additionalPayments.any(
          (p) =>
              p.amount == null ||
              !validMoney(p.amount!) ||
              p.amount! <= 0 ||
              !validDate(p.dueDate),
        )) {
      result.add('additionalPayments');
    }
    final extras = additionalPayments.fold<double>(
      0,
      (sum, p) => sum + (p.amount ?? 0),
    );
    if (extras > (remainingBalance ?? 0) + 0.001) {
      result.add('additionalPayments');
    }
    if (combinedPrice != null && !validMoney(combinedPrice!)) {
      result.add('sellerAmount');
    }
    return result;
  }

  static bool validMoney(double value) =>
      value.isFinite &&
      value >= 0 &&
      value <= 9999999999.99 &&
      (value * 100 - (value * 100).round()).abs() < 0.001;

  static bool validDate(String? value) {
    if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final date = DateTime.tryParse(value);
    return date != null && date.toIso8601String().startsWith(value);
  }
}
