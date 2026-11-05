import 'package:intl/intl.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';

/// One receipt email, as it would be sent.
class ReceiptEmail {
  final String to;
  final String subject;
  final String body;

  const ReceiptEmail({
    required this.to,
    required this.subject,
    required this.body,
  });
}

/// Emails the receipt of a completed payment to the payer.
///
/// Real receipts must be sent by the payment service once ABA has confirmed
/// the payment (see genie-backend docs/ABA_PAYWAY_INTEGRATION.md); the app
/// will then only show that it was sent.
abstract interface class ReceiptMailer {
  Future<ReceiptEmail> send(PaymentReceipt receipt);
}

/// Writes the email the payer would get to the log instead of sending it.
class MockReceiptMailer implements ReceiptMailer {
  /// Every email "sent", oldest first.
  final List<ReceiptEmail> sent = [];

  @override
  Future<ReceiptEmail> send(PaymentReceipt receipt) async {
    final email = compose(receipt);
    sent.add(email);
    AppLogger.debug(
      '[mock email] To: ${email.to}\nSubject: ${email.subject}\n\n${email.body}',
    );
    return email;
  }

  /// The receipt as an email, in English (what the server will send).
  static ReceiptEmail compose(PaymentReceipt receipt) {
    final amount = NumberFormat.currency(
      locale: 'en_US',
      symbol: r'$',
    ).format(receipt.amountUsd);
    final paidAt = DateFormat('d MMM yyyy, HH:mm').format(receipt.paidAt);
    final method = switch (receipt.method) {
      PaymentMethod.abaPay => 'ABA PAY',
      PaymentMethod.abaKhqr => 'ABA KHQR',
    };
    return ReceiptEmail(
      to: receipt.email!,
      subject: 'Tilomnov receipt #${receipt.transactionId}',
      body: [
        'Thank you for your payment.',
        '',
        'Item: ${receipt.item}',
        'Amount paid: $amount (10% tax included)',
        'Payment method: $method',
        'Transaction ID: #${receipt.transactionId}',
        'Date: $paidAt',
        '',
        'Keep this email as your receipt.',
        'Tilomnov',
      ].join('\n'),
    );
  }
}
