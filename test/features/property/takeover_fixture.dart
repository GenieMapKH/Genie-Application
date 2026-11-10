import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/models/takeover_terms.dart';

const takeoverFixture = TakeoverTerms(
  providerType: 'Developer',
  providerName: 'Example Developer',
  projectName: 'Example Project',
  sellerAmount: 20000.25,
  remainingBalance: 60000,
  balanceAsOf: '2026-11-08',
  paymentAmount: 500.75,
  paymentFrequency: 'Monthly',
  remainingMonths: 120,
  nextPaymentDate: '2026-12-08',
  interestType: 'Fixed',
  annualInterestRate: 6.75,
  transferStatus: 'Conditional',
  transferFee: null,
  transferFeePayer: 'Buyer',
  arrearsAmount: 0,
  hasAdditionalPayments: true,
  additionalPayments: [TakeoverPayment(amount: 10000, dueDate: '2027-01-01')],
);

PropertyModel takeoverListingFixture() => PropertyModel.fromJson({
  'id': 'takeover-1',
  'title': 'House with payment plan',
  'price': '80000.25',
  'propertyType': 'House',
  'listingType': takeoverListingType,
  'status': 'Active',
  'createdAt': '2026-11-08T00:00:00.000Z',
  'takeover': takeoverFixture.toJson(),
});
