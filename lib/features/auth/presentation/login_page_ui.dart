// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'login_page.dart';

extension LoginPageUI on _LoginPageState {
  Widget _buildLoginUI(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen<AsyncValue<void>>(loginControllerProvider, (_, state) {
      if (!state.isLoading && state.hasError) {
        final errorMessage = state.error is AppException
            ? (state.error as AppException).message
            : 'Login failed. Please check your credentials and try again.';
        AppPopup.showError(context, errorMessage);
      } else if (!state.isLoading && !state.hasError && state.hasValue) {
        AppPopup.showSuccess(context, 'Successfully logged in!');

        // Invalidate providers so they fetch fresh data for the newly logged-in user
        ref.invalidate(userProfileProvider);
        ref.invalidate(propertiesProvider);
        ref.invalidate(publicPropertiesProvider);

        if (widget.onLoginPressed != null) {
          widget.onLoginPressed!();
        } else {
          context.go('/home');
        }
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 408.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Header with animated entrance
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Welcome back to the app',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auth Method Tabs with Sliding Underline Indicator
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: _buildAnimatedTabBar(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields with Directional Slide & Fade Transition
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final isEmail =
                                      child.key == const Key('email_field');
                                  final offsetTween = Tween<Offset>(
                                    begin: isEmail
                                        ? const Offset(-0.08, 0)
                                        : const Offset(0.08, 0),
                                    end: Offset.zero,
                                  );
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: offsetTween.animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _selectedMethod == AuthMethod.email
                                    ? AppTextField(
                                        key: const Key('email_field'),
                                        label: 'Email Address',
                                        hintText: 'example@gmail.com',
                                        errorText: _emailError,
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (val) {
                                          if (_emailError != null) {
                                            setState(() {
                                              _emailError = _validateEmail(val)
                                                  ? null
                                                  : 'Enter a valid email address';
                                            });
                                          }
                                        },
                                      )
                                    : AppTextField(
                                        key: const Key('phone_field'),
                                        label: 'Phone number',
                                        hintText: 'Phone number',
                                        errorText: _phoneError,
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (val) {
                                          if (_phoneError != null) {
                                            setState(() {
                                              _phoneError = _validatePhone(val)
                                                  ? null
                                                  : 'Enter a valid phone number';
                                            });
                                          }
                                        },
                                      ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field with "Forget Password?" link & Error handling
                              AppTextField(
                                key: const Key('password_field'),
                                label: 'Password',
                                hintText: '••••••••••••',
                                errorText: _passwordError,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onChanged: (val) {
                                  if (_passwordError != null) {
                                    setState(() {
                                      if (val.isEmpty) {
                                        _passwordError =
                                            'Enter a valid password';
                                      } else if (val.length < 6) {
                                        _passwordError =
                                            'Password must be at least 6 characters';
                                      } else {
                                        _passwordError = null;
                                      }
                                    });
                                  }
                                },
                                topTrailingWidget: GestureDetector(
                                  onTap:
                                      widget.onForgotPasswordPressed ?? () {},
                                  child: Text(
                                    'Forget Password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4F5BD5),
                                    ),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      key: ValueKey<bool>(_obscurePassword),
                                      color: const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Keep me signed in Checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _keepMeSignedIn,
                                      activeColor: const Color(0xFF4F5BD5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _keepMeSignedIn = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _keepMeSignedIn = !_keepMeSignedIn;
                                      });
                                    },
                                    child: Text(
                                      'Keep me signed in',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Actions Section with staggered entrance
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _actionsSlide,
                        child: FadeTransition(
                          opacity: _actionsFade,
                          child: Column(
                            children: [
                              // Primary Login Button (#4F5BD5)
                              AppButton.primary(
                                text: 'Login',
                                isLoading: loginState.isLoading,
                                onPressed: _handleLogin,
                              ),
                              const SizedBox(height: 24),

                              // Divider: "or sign in with"
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFE5E7EB),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      'or sign in with',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFE5E7EB),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Google OAuth Login Button
                              AppButton(
                                text: 'Continue with Google',
                                backgroundColor: Colors.white,
                                textColor: const Color(0xFF1F2937),
                                borderColor: const Color(0xFFE5E7EB),
                                borderWidth: 1.5,
                                icon: const GoogleIcon(size: 20),
                                onPressed: widget.onGoogleLoginPressed ?? () {},
                              ),
                              const SizedBox(height: 54),

                              // Bottom Link: Create a Account
                              Center(
                                child: GestureDetector(
                                  onTap:
                                      widget.onCreateAccountPressed ??
                                      () {
                                        context.go('/register');
                                      },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
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
                              ),
                              const SizedBox(height: 16),
                            ],
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
    );
  }

  Widget _buildAnimatedTabBar() {
    final isEmail = _selectedMethod == AuthMethod.email;

    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_selectedMethod != AuthMethod.email) {
                    setState(() {
                      _selectedMethod = AuthMethod.email;
                      _phoneError = null;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isEmail ? FontWeight.w600 : FontWeight.w500,
                      color: isEmail
                          ? const Color(0xFF4F5BD5)
                          : const Color(0xFF64748B),
                    ),
                    child: const Text('Email'),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () {
                  if (_selectedMethod != AuthMethod.phone) {
                    setState(() {
                      _selectedMethod = AuthMethod.phone;
                      _emailError = null;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: !isEmail ? FontWeight.w600 : FontWeight.w500,
                      color: !isEmail
                          ? const Color(0xFF4F5BD5)
                          : const Color(0xFF64748B),
                    ),
                    child: const Text('Phone Number'),
                  ),
                ),
              ),
            ],
          ),

          // Sliding Underline Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            left: isEmail ? 0 : 64.0,
            bottom: 0,
            width: isEmail ? 40.0 : 110.0,
            height: 2.0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4F5BD5),
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
