import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/shared/widgets/app_text_field.dart';
import 'package:genie/shared/utils/app_popup.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  bool _validateEmail(String value) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(value.trim());
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError =
          _validateEmail(email) ? null : 'Please enter a valid email address';
    });

    if (_emailError != null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).forgotPassword(email);
      if (!mounted) return;
      AppPopup.showSuccess(context, 'Verification code sent to your email');
      context.push('/verify-otp?email=${Uri.encodeComponent(email)}');
    } catch (e) {
      if (!mounted) return;
      AppPopup.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Forgot Password',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your email address to get the password reset link.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email field
                      AppTextField(
                        label: 'Email Address',
                        hintText: 'example@gmail.com',
                        controller: _emailController,
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onChanged: (val) {
                          if (_emailError != null) {
                            setState(() {
                              _emailError = _validateEmail(val)
                                  ? null
                                  : 'Please enter a valid email address';
                            });
                          }
                        },
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F5BD5),
                            disabledBackgroundColor: const Color(0x994F5BD5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Password Reset',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Create account link
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text(
                            'Create a Account',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F5BD5),
                            ),
                          ),
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
