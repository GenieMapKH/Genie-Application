import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/shared/utils/phone_number.dart';

import 'login_controller.dart';

enum AuthMethod { email, phone }

/// What is wrong with a field of the form. The page says it in the user's
/// language.
enum LoginFieldError {
  invalidEmail,
  invalidPhone,
  missingPassword,
  shortPassword,
}

class LoginFormState {
  final AuthMethod selectedMethod;
  final String email;
  final String phone;
  final String password;
  final LoginFieldError? emailError;
  final LoginFieldError? phoneError;
  final LoginFieldError? passwordError;
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
    LoginFieldError? emailError,
    LoginFieldError? phoneError,
    LoginFieldError? passwordError,
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
        state = state.copyWith(emailError: LoginFieldError.invalidEmail);
      }
    }
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
    if (state.phoneError != null) {
      if (_validatePhone(phone)) {
        state = state.copyWith(clearPhoneError: true);
      } else {
        state = state.copyWith(phoneError: LoginFieldError.invalidPhone);
      }
    }
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
    if (state.passwordError != null) {
      if (password.isEmpty) {
        state = state.copyWith(passwordError: LoginFieldError.missingPassword);
      } else if (password.length < 6) {
        state = state.copyWith(passwordError: LoginFieldError.shortPassword);
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

  /// Same rule as sign-up and the server: `012 345 678`, `+855 12 345 678`...
  bool _validatePhone(String value) => normalizePhoneNumber(value) != null;

  bool validateForm() {
    bool isValid = true;
    LoginFieldError? emailError;
    LoginFieldError? phoneError;
    LoginFieldError? passwordError;

    if (state.selectedMethod == AuthMethod.email) {
      if (!_validateEmail(state.email)) {
        emailError = LoginFieldError.invalidEmail;
        isValid = false;
      }
    } else {
      if (!_validatePhone(state.phone)) {
        phoneError = LoginFieldError.invalidPhone;
        isValid = false;
      }
    }

    if (state.password.isEmpty) {
      passwordError = LoginFieldError.missingPassword;
      isValid = false;
    } else if (state.password.length < 6) {
      passwordError = LoginFieldError.shortPassword;
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

  Future<bool> submit() async {
    if (!validateForm()) return false;

    final controller = ref.read(loginControllerProvider.notifier);

    if (state.selectedMethod == AuthMethod.email) {
      return controller.login(state.email.trim(), state.password);
    } else {
      return controller.login(
        normalizePhoneNumber(state.phone)!,
        state.password,
      );
    }
  }
}

final loginFormProvider =
    AutoDisposeNotifierProvider<LoginFormNotifier, LoginFormState>(() {
      return LoginFormNotifier();
    });
