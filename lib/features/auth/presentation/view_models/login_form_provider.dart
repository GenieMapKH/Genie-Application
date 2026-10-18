import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_controller.dart';

enum AuthMethod { email, phone }

class LoginFormState {
  final AuthMethod selectedMethod;
  final String email;
  final String phone;
  final String password;
  final String? emailError;
  final String? phoneError;
  final String? passwordError;
  final bool obscurePassword;
  final bool keepMeSignedIn;

  const LoginFormState({
    this.selectedMethod = AuthMethod.email,
    this.email = '',
    this.phone = '',
    this.password = '',
    this.emailError,
    this.phoneError,
    this.passwordError,
    this.obscurePassword = true,
    this.keepMeSignedIn = true,
  });

  LoginFormState copyWith({
    AuthMethod? selectedMethod,
    String? email,
    String? phone,
    String? password,
    String? emailError,
    String? phoneError,
    String? passwordError,
    bool? obscurePassword,
    bool? keepMeSignedIn,
    bool clearEmailError = false,
    bool clearPhoneError = false,
    bool clearPasswordError = false,
  }) {
    return LoginFormState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      obscurePassword: obscurePassword ?? this.obscurePassword,
      keepMeSignedIn: keepMeSignedIn ?? this.keepMeSignedIn,
    );
  }
}

class LoginFormNotifier extends AutoDisposeNotifier<LoginFormState> {
  @override
  LoginFormState build() {
    return const LoginFormState();
  }

  void setMethod(AuthMethod method) {
    state = state.copyWith(
      selectedMethod: method,
      clearEmailError: true,
      clearPhoneError: true,
    );
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
    if (state.emailError != null) {
      if (_validateEmail(email)) {
        state = state.copyWith(clearEmailError: true);
      } else {
        state = state.copyWith(emailError: 'Enter a valid email address');
      }
    }
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
    if (state.phoneError != null) {
      if (_validatePhone(phone)) {
        state = state.copyWith(clearPhoneError: true);
      } else {
        state = state.copyWith(phoneError: 'Enter a valid phone number');
      }
    }
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
    if (state.passwordError != null) {
      if (password.isEmpty) {
        state = state.copyWith(passwordError: 'Enter a valid password');
      } else if (password.length < 6) {
        state = state.copyWith(
          passwordError: 'Password must be at least 6 characters',
        );
      } else {
        state = state.copyWith(clearPasswordError: true);
      }
    }
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void setKeepMeSignedIn(bool keep) {
    state = state.copyWith(keepMeSignedIn: keep);
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return emailRegex.hasMatch(value.trim());
  }

  bool _validatePhone(String value) {
    final clean = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    return phoneRegex.hasMatch(clean);
  }

  bool validateForm() {
    bool isValid = true;
    String? emailError;
    String? phoneError;
    String? passwordError;

    if (state.selectedMethod == AuthMethod.email) {
      if (!_validateEmail(state.email)) {
        emailError = 'Enter a valid email address';
        isValid = false;
      }
    } else {
      if (!_validatePhone(state.phone)) {
        phoneError = 'Enter a valid phone number';
        isValid = false;
      }
    }

    if (state.password.isEmpty) {
      passwordError = 'Enter a valid password';
      isValid = false;
    } else if (state.password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
      isValid = false;
    }

    state = state.copyWith(
      emailError: emailError,
      phoneError: phoneError,
      passwordError: passwordError,
      clearEmailError: emailError == null,
      clearPhoneError: phoneError == null,
      clearPasswordError: passwordError == null,
    );

    return isValid;
  }

  /// [afterSignIn] as in [LoginController.login].
  Future<bool> submit({
    Future<void> Function(String password)? afterSignIn,
  }) async {
    if (!validateForm()) return false;

    final controller = ref.read(loginControllerProvider.notifier);

    if (state.selectedMethod == AuthMethod.email) {
      return controller.login(
        state.email.trim(),
        state.password,
        afterSignIn: afterSignIn,
      );
    } else {
      final cleanPhone = state.phone.replaceAll(RegExp(r'[\s\-()]'), '');
      return controller.login(
        cleanPhone,
        state.password,
        afterSignIn: afterSignIn,
      );
    }
  }
}

final loginFormProvider =
    AutoDisposeNotifierProvider<LoginFormNotifier, LoginFormState>(() {
      return LoginFormNotifier();
    });
