import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/e2ee/backup/pin_check.dart';
import 'package:tilomnov/features/chat/presentation/widgets/pin/pin_code_field.dart';
import 'package:tilomnov/features/chat/presentation/widgets/pin/pin_status_line.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Asks for the chat PIN and checks each one typed with [check] while the
/// dialog stays open: a wrong PIN says how many tries are left, and after
/// too many the dialog counts down until the next try. True once a PIN was
/// accepted, false if the user closed the dialog.
Future<bool> showPinCheckDialog(
  BuildContext context, {
  required String title,
  required String helper,
  required PinCheck check,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinCheckDialog(title: title, helper: helper, check: check),
  );
  return accepted ?? false;
}

class _PinCheckDialog extends StatefulWidget {
  final String title;
  final String helper;
  final PinCheck check;

  const _PinCheckDialog({
    required this.title,
    required this.helper,
    required this.check,
  });

  @override
  State<_PinCheckDialog> createState() => _PinCheckDialogState();
}

class _PinCheckDialogState extends State<_PinCheckDialog> {
  final _controller = TextEditingController();
  bool _checking = false;
  PinCheckResult? _last;
  int _shakes = 0;

  /// How long the lock after too many wrong PINs still lasts, if the
  /// server said.
  Duration? _lockLeft;
  Timer? _ticker;

  bool get _lockedOut => _last is PinLockedOut;

  @override
  void initState() {
    super.initState();
    // The Unlock button follows what is typed.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text;
    if (pin.length != PinCodeField.length || _checking || _lockedOut) return;

    setState(() => _checking = true);
    final result = await widget.check(pin);
    if (!mounted) return;

    if (result is PinAccepted) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _checking = false;
      _last = result;
      if (result is! PinCheckFailed) {
        // A wrong PIN is typed again from the start.
        _controller.clear();
        _shakes++;
      }
    });
    if (result is PinLockedOut) _startCountdown(result.retryAfter);
  }

  void _startCountdown(Duration? retryAfter) {
    _ticker?.cancel();
    if (retryAfter == null) return;
    _lockLeft = retryAfter;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _lockLeft! - const Duration(seconds: 1);
      setState(() {
        if (left > Duration.zero) {
          _lockLeft = left;
          return;
        }
        // The lock is over: the next PIN can be typed.
        _ticker?.cancel();
        _last = null;
        _lockLeft = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final hasError = _last is PinRejected || _lockedOut;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _lockedOut
                ? colors.dangerSoft
                : colors.primarySoft,
            child: Icon(
              _lockedOut ? Icons.lock_clock_outlined : Icons.lock_outline,
              color: _lockedOut ? colors.danger : colors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(widget.title, textAlign: TextAlign.center),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.helper,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            PinCodeField(
              controller: _controller,
              enabled: !_checking && !_lockedOut,
              hasError: hasError,
              shakeCount: _shakes,
              onCompleted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            PinStatusLine(
              checking: _checking,
              result: _last,
              lockLeft: _lockLeft,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pinForgotHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: colors.textHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed:
              _checking ||
                  _lockedOut ||
                  _controller.text.length != PinCodeField.length
              ? null
              : _submit,
          child: Text(l10n.pinUnlock),
        ),
      ],
    );
  }
}
