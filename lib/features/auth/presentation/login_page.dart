import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genie/features/auth/presentation/controllers/login_controller.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/app_button.dart';
import 'package:genie/shared/widgets/app_text_field.dart';
import 'package:genie/shared/widgets/google_icon.dart';
import 'package:genie/features/property/data/property_providers.dart';
import 'package:genie/features/profile/data/user_providers.dart';

part 'login_page_ui.dart';

enum AuthMethod { email, phone }

/// Login screen supporting Email and Phone Number authentication methods,
/// Google OAuth login, "Keep me signed in" preference, and custom error states.
class LoginPage extends ConsumerStatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onGoogleLoginPressed;
  final VoidCallback? onForgotPasswordPressed;
  final VoidCallback? onCreateAccountPressed;

  const LoginPage({
    super.key,
    this.onLoginPressed,
    this.onGoogleLoginPressed,
    this.onForgotPasswordPressed,
    this.onCreateAccountPressed,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  AuthMethod _selectedMethod = AuthMethod.email;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  bool _obscurePassword = true;
  bool _keepMeSignedIn = true;

  late AnimationController _entryController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _actionsFade;
  late Animation<Offset> _actionsSlide;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _actionsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _actionsSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  bool _validateForm() {
    var isValid = true;

    setState(() {
      if (_selectedMethod == AuthMethod.email) {
        if (!_validateEmail(_emailController.text)) {
          _emailError = 'Enter a valid email address';
          isValid = false;
        } else {
          _emailError = null;
        }
      } else {
        if (!_validatePhone(_phoneController.text)) {
          _phoneError = 'Enter a valid phone number';
          isValid = false;
        } else {
          _phoneError = null;
        }
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Enter a valid password';
        isValid = false;
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        isValid = false;
      } else {
        _passwordError = null;
      }
    });

    return isValid;
  }

  Future<void> _handleLogin() async {
    final isValid = _validateForm();
    if (isValid) {
      if (_selectedMethod == AuthMethod.email) {
        await ref
            .read(loginControllerProvider.notifier)
            .login(_emailController.text, _passwordController.text);
      } else {
        // Placeholder for phone login
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return _buildLoginUI(context);
  }
}
