import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/presentation/auth_error_message.dart';
import 'package:genie/l10n/l10n.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;

  /// The server sends at most one code per address a minute.
  static const _resendWaitSeconds = 60;

  int _resendCountdown = _resendWaitSeconds;
  Timer? _resendTimer;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _entryController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = _resendWaitSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste: distribute digits across boxes
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      // Focus the last filled box or the next empty one
      final focusIndex = digits.length >= _otpLength
          ? _otpLength - 1
          : digits.length;
      if (focusIndex < _otpLength) {
        _focusNodes[focusIndex].requestFocus();
      }
      setState(() {});
      if (digits.length >= _otpLength) {
        _handleVerify();
      }
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        setState(() {});
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otpValue;
    if (otp.length != _otpLength) {
      AppPopup.showError(context, context.l10n.authPleaseEnterAll6Digits);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final verified = await ref
          .read(authServiceProvider)
          .verifyOtp(widget.email, otp);
      if (!mounted) return;
      if (verified) {
        context.push(
          '/reset-password?email=${Uri.encodeComponent(widget.email)}&otp=${Uri.encodeComponent(otp)}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppPopup.showError(
        context,
        authErrorMessage(
          context.l10n,
          e,
          badRequest: context.l10n.authErrorInvalidCode,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0) return;

    try {
      await ref.read(authServiceProvider).forgotPassword(widget.email);
      if (!mounted) return;
      AppPopup.showSuccess(context, context.l10n.authNewVerificationCodeSent);
      _startResendTimer();
      // Clear existing OTP
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      AppPopup.showError(context, authErrorMessage(context.l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 408.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        context.l10n.authOtpVerification,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.authEnterTheVerificationCodeWeJust,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: context.colors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_otpLength, (index) {
                          final isFilled = _controllers[index].text.isNotEmpty;
                          final isFocused = _focusNodes[index].hasFocus;

                          return Container(
                            width: 48,
                            height: 56,
                            margin: EdgeInsets.only(
                              right: index < _otpLength - 1 ? 10 : 0,
                            ),
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) => _onKeyDown(index, event),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                maxLength: _otpLength,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: isFocused || isFilled
                                          ? context.colors.primary
                                          : context.colors.border,
                                      width: isFocused ? 2 : 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: isFilled
                                          ? context.colors.primary
                                          : context.colors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: context.colors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (value) =>
                                    _onOtpChanged(index, value),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            disabledBackgroundColor: context.colors.primary
                                .withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: context.colors.onPrimary,
                                  ),
                                )
                              : Text(
                                  context.l10n.authVerify,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Resend OTP
                      Center(
                        child: Column(
                          children: [
                            Text(
                              context.l10n.authResendOtpIn(_resendCountdown),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: _resendCountdown == 0
                                  ? _handleResend
                                  : null,
                              child: Text(
                                context.l10n.authResendOtp,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _resendCountdown == 0
                                      ? context.colors.primary
                                      : context.colors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
