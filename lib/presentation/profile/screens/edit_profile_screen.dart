import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          return _EditProfileForm(user: user);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  final UserModel user;
  const _EditProfileForm({required this.user});

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final TextEditingController _nameCtrl;
  late String _branch;
  late String _year;
  String? _pendingAvatarUrl;
  File? _pendingAvatarFile;
  bool _saving = false;
  bool _uploadingAvatar = false;

  // Branches/years the user is currently saved with might not exactly match
  // the canonical constants list (e.g. legacy/bad data), so we make sure the
  // dropdown always has a matching value to avoid a Flutter assertion crash.
  late final List<String> _branchItems;
  late final List<String> _yearItems;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);

    final savedBranch = widget.user.branch.trim();
    _branchItems = savedBranch.isNotEmpty && !AppConstants.branches.contains(savedBranch)
        ? [savedBranch, ...AppConstants.branches]
        : List.of(AppConstants.branches);
    _branch = savedBranch.isNotEmpty ? savedBranch : AppConstants.branches.first;

    final savedYear = widget.user.year.trim();
    _yearItems = savedYear.isNotEmpty && !AppConstants.years.contains(savedYear)
        ? [savedYear, ...AppConstants.years]
        : List.of(AppConstants.years);
    _year = savedYear.isNotEmpty ? savedYear : AppConstants.years.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _pendingAvatarFile = File(picked.path));
  }

  bool get _hasChanges =>
      _nameCtrl.text.trim() != widget.user.name ||
      _branch != widget.user.branch ||
      _year != widget.user.year ||
      _pendingAvatarFile != null;

  Future<void> _save() async {
    final trimmedName = _nameCtrl.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (!_hasChanges) {
      context.pop();
      return;
    }

    setState(() => _saving = true);
    try {
      // Upload avatar first if a new one was picked
      if (_pendingAvatarFile != null) {
        setState(() => _uploadingAvatar = true);
        _pendingAvatarUrl = await ref.read(storageServiceProvider).uploadAvatar(
              widget.user.uid,
              _pendingAvatarFile!,
            );
        if (mounted) setState(() => _uploadingAvatar = false);
      }

      final updates = <String, dynamic>{
        'name': trimmedName,
        'branch': _branch,
        'year': _year,
        if (_pendingAvatarUrl != null) 'avatarUrl': _pendingAvatarUrl,
      };

      await ref.read(userServiceProvider).updateUser(widget.user.uid, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    _pendingAvatarFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.file(
                              _pendingAvatarFile!,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                          )
                        : ClubAvatar(imageUrl: user.avatarUrl, name: user.name, size: 96),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: _uploadingAvatar
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _label('Full Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Enter your full name'),
              ),
              const SizedBox(height: 20),

              _label('Email'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.email,
                        style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                          items: _branchItems,
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
                          items: _yearItems,
                          onChanged: (v) => setState(() => _year = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Save Changes',
                  onTap: _save,
                  isLoading: _saving,
                  height: 52,
                ),
              ),
            ],
          ),
        ),
        if (_saving)
          Container(
            color: Colors.black.withValues(alpha: 0.15),
          ),
      ],
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

// ─── Small local dropdown, matches the register screen's style ───────────────

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
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 18),
      ),
    );
  }
}