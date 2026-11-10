import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:tilomnov/core/device/app_haptics.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/core/theme/app_motion.dart';
import 'package:tilomnov/features/payment/data/receipt_saver.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/payment/presentation/widgets/receipt_card.dart';
import 'package:tilomnov/features/payment/presentation/widgets/success_seal.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';

/// "Success": shown once a payment has gone through. The seal springs in,
/// the details rise into place, and the receipt can be kept as a picture.
/// [onDone] leaves it ("Back to Home", or the system back).
class PaymentSuccessPage extends StatefulWidget {
  final PaymentReceipt receipt;
  final VoidCallback onDone;
  final ReceiptSaver saver;

  const PaymentSuccessPage({
    super.key,
    required this.receipt,
    required this.onDone,
    this.saver = const ReceiptSaver(),
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final _receiptKey = GlobalKey();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduceMotionOf(context)) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
      AppHaptics.firmTap();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Draws the receipt card and keeps it in the photos.
  Future<void> _downloadReceipt() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    try {
      final png = await _captureReceipt();
      if (png == null) throw StateError('The receipt could not be drawn');
      final saved = await widget.saver.saveToPhotos(
        png,
        name: 'tilomnov-receipt-${widget.receipt.transactionId}',
      );
      if (!mounted) return;
      saved
          ? AppPopup.showSuccess(context, l10n.paymentReceiptSaved)
          : AppPopup.showError(context, l10n.paymentReceiptPhotosDenied);
    } catch (e, stackTrace) {
      AppLogger.error('Saving the receipt failed', e, stackTrace);
      if (mounted) AppPopup.showError(context, l10n.paymentReceiptSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List?> _captureReceipt() async {
    final boundary =
        _receiptKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// [child] fades and rises into place over [start]–[end] of the entrance.
  Widget _rise(double start, double end, Widget child) {
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: AppMotion.easeOut),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final receipt = widget.receipt;
    final email = receipt.email;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDone();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            // Off screen: drawn only to be captured by Download Receipt.
            Positioned(
              left: -ReceiptCard.width * 3,
              top: 0,
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  key: _receiptKey,
                  child: ReceiptCard(receipt: receipt),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Text(
                    'Tilomnov',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 56),
                  Center(child: SuccessSeal(progress: _entrance)),
                  const SizedBox(height: 4),
                  _rise(
                    0.45,
                    0.75,
                    Text(
                      l10n.paymentSuccessTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  _rise(
                    0.52,
                    0.82,
                    Text(
                      l10n.paymentSuccessAmount(
                        formatUsdShort(receipt.amountUsd),
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _rise(
                    0.58,
                    0.88,
                    Text(
                      l10n.paymentSuccessTransaction(receipt.transactionId),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _rise(
                    0.64,
                    0.94,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        email == null
                            ? l10n.paymentSuccessNoEmail
                            : '${l10n.paymentSuccessEmailed}\n$email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _rise(
                    0.72,
                    1,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          _SuccessButton(
                            label: l10n.paymentDownloadReceipt,
                            filled: true,
                            busy: _saving,
                            onPressed: _downloadReceipt,
                          ),
                          const SizedBox(height: 14),
                          _SuccessButton(
                            label: l10n.paymentBackToHome,
                            filled: false,
                            onPressed: widget.onDone,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The two wide buttons at the foot: filled in the brand colour, or white
/// with a hairline.
class _SuccessButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback onPressed;

  const _SuccessButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = filled ? colors.onPrimary : colors.textPrimary;
    return TactileButton(
      onPressed: busy ? null : onPressed,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: colors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: (filled ? colors.primary : Colors.black).withValues(
                alpha: filled ? 0.25 : 0.04,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: busy
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: ink),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
      ),
    );
  }
}
