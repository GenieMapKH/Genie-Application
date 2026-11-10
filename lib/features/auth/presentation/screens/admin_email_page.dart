import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';

class AdminEmailPage extends ConsumerStatefulWidget {
  const AdminEmailPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<AdminEmailPage> createState() => _AdminEmailPageState();
}

class _AdminEmailPageState extends ConsumerState<AdminEmailPage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) _complete();
  }

  Future<void> _complete() async {
    try {
      await ref.read(authServiceProvider).completeAdminLogin(widget.token!);
      if (!mounted) return;
      ref.invalidate(publicPropertiesProvider);
      context.go('/home');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final verifying = widget.token != null && !_failed;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminEmailTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (verifying)
                  const CircularProgressIndicator()
                else
                  Icon(
                    _failed
                        ? Icons.error_outline
                        : Icons.mark_email_unread_outlined,
                    size: 64,
                  ),
                const SizedBox(height: 24),
                Text(
                  verifying
                      ? l10n.adminEmailVerifying
                      : _failed
                      ? l10n.adminEmailInvalid
                      : l10n.adminEmailWaiting,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!verifying)
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l10n.adminEmailBack),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
