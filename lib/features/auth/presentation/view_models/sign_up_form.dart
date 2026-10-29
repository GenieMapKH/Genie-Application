import 'package:tilomnov/shared/utils/email_address.dart';
import 'package:tilomnov/shared/utils/phone_number.dart';

/// What is wrong with one field of the sign-up form. The page says it in
/// the user's language.
enum SignUpProblem {
  missingName,
  invalidPhone,
  invalidEmail,
  missingPassword,
  shortPassword,
  termsNotAccepted,
}

/// What the user typed on the sign-up page, and the rules it must meet
/// before it is sent. The server checks the same rules again.
class SignUpForm {
  /// Same rule as the server.
  static const minPasswordLength = 8;

  final String name;
  final String phone;
  final String email;
  final String password;
  final bool agreedToTerms;

  const SignUpForm({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.agreedToTerms,
  });

  /// The trimmed name.
  String get trimmedName => name.trim();

  /// The phone number as the server stores it, or null if it is not one.
  String? get normalizedPhone => normalizePhoneNumber(phone);

  /// The email to send, or null when the optional field was left empty.
  String? get normalizedEmail {
    final trimmed = email.trim().toLowerCase();
    return trimmed.isEmpty ? null : trimmed;
  }

  SignUpProblem? get nameProblem =>
      trimmedName.isEmpty ? SignUpProblem.missingName : null;

  SignUpProblem? get phoneProblem =>
      normalizedPhone == null ? SignUpProblem.invalidPhone : null;

  /// Only a typed email can be wrong: it is optional.
  SignUpProblem? get emailProblem {
    final value = normalizedEmail;
    return value != null && !isValidEmail(value)
        ? SignUpProblem.invalidEmail
        : null;
  }

  SignUpProblem? get passwordProblem {
    if (password.isEmpty) return SignUpProblem.missingPassword;
    if (password.length < minPasswordLength) {
      return SignUpProblem.shortPassword;
    }
    return null;
  }

  SignUpProblem? get termsProblem =>
      agreedToTerms ? null : SignUpProblem.termsNotAccepted;

  bool get isValid =>
      nameProblem == null &&
      phoneProblem == null &&
      emailProblem == null &&
      passwordProblem == null &&
      termsProblem == null;
}
