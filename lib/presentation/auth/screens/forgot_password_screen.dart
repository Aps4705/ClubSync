import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/services/firebase_services.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (_) {
      setState(() => _error = 'Failed to send reset email. Check the address and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 24),
                  Text('Email Sent', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Check your inbox for password reset instructions.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Back to Sign In',
                    onTap: () => context.go('/auth/login'),
                    width: double.infinity,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reset Password',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your KIET email and we\'ll send a reset link.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'yourname@kiet.edu',
                      prefixIcon: Icon(Icons.email_outlined, size: 18,
                          color: AppColors.textMuted),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Send Reset Link',
                    onTap: _send,
                    isLoading: _loading,
                    width: double.infinity,
                  ),
                ],
              ),
      ),
    );
  }
}