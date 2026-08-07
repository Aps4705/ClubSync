import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/services/firebase_services.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  String? _message;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 5s so the app moves on automatically once the user
    // clicks the verification link in their email — no manual refresh needed.
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerified(silent: true));
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() { _sending = true; _message = null; });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) setState(() => _message = 'Verification email sent! Check your inbox.');
    } catch (e) {
      if (mounted) setState(() => _message = 'Failed to send email. Try again in a moment.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (!silent) setState(() => _checking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (verified && mounted) {
        // Force the auth stream to re-emit so the router redirect re-evaluates.
        ref.invalidate(authStateProvider);
      } else if (!silent && mounted) {
        setState(() => _message = 'Not verified yet — check your inbox and spam folder.');
      }
    } finally {
      if (!silent && mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
                child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              Text('Verify your email', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to\n$email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Click the link, then come back here — this screen updates automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: "I've verified — Continue",
                  onTap: () => _checkVerified(),
                  isLoading: _checking,
                  height: 50,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _sending ? null : _resend,
                child: Text(_sending ? 'Sending...' : 'Resend verification email'),
              ),
              TextButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text('Sign out', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}