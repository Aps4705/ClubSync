import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/services/firebase_services.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _branch = AppConstants.branches.first;
  String _year = AppConstants.years.first;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

Future<void> _register() async {
  if (_nameCtrl.text.trim().isEmpty) {
    setState(() => _error = 'Please enter your name.');
    return;
  }
  setState(() { _loading = true; _error = null; });
  try {
    final user = await ref.read(authServiceProvider).register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      branch: _branch,
      year: _year,
    );
    // Initialize notifications after successful registration
    await ref.read(notificationServiceProvider).initialize(user.uid);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please verify your email.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    setState(() => _error = e.toString().contains('kiet.edu')
        ? 'Only @kiet.edu email addresses are allowed.'
        : 'Registration failed. Please try again.');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Join ClubSync with your KIET email.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              _label('Full Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Rahul Sharma',
                  prefixIcon: Icon(Icons.person_outline, size: 18,
                      color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 16),
              _label('College Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'yourname@kiet.edu',
                  prefixIcon: Icon(Icons.email_outlined, size: 18,
                      color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 16),
              _label('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Min. 8 characters',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18,
                      color: AppColors.textMuted),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Branch'),
                        const SizedBox(height: 8),
                        _Dropdown(
                          value: _branch,
                          items: AppConstants.branches,
                          onChanged: (v) => setState(() => _branch = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Year'),
                        const SizedBox(height: 8),
                        _Dropdown(
                          value: _year,
                          items: AppConstants.years,
                          onChanged: (v) => setState(() => _year = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Create Account',
                  onTap: _register,
                  isLoading: _loading,
                  height: 52,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text('Sign in',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      );
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          fillColor: Colors.transparent,
          filled: false,
        ),
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted, size: 18),
      ),
    );
  }
}
