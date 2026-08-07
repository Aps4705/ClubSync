import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';
import '../../../core/constants/app_constants.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final TeamUpPost? editPost;
  const CreatePostScreen({super.key, this.editPost});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late final _titleCtrl = TextEditingController(text: widget.editPost?.title ?? '');
  late final _descCtrl = TextEditingController(text: widget.editPost?.description ?? '');
  late final _contactCtrl = TextEditingController(text: widget.editPost?.contactInfo ?? '');
  late final _hackathonCtrl = TextEditingController(text: widget.editPost?.linkedHackathon ?? '');
  final _customSkillCtrl = TextEditingController();
  late final List<String> _selectedSkills = List.of(widget.editPost?.skillsNeeded ?? []);
  bool _loading = false;

  bool get _isEditing => widget.editPost != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    _hackathonCtrl.dispose();
    _customSkillCtrl.dispose();
    super.dispose();
  }

  
  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
  static final _phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');

  String? _validateContactInfo(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Contact info is required';
    final isUrl = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final isEmail = _emailRegex.hasMatch(trimmed);
    final isPhone = _phoneRegex.hasMatch(trimmed);
    if (!isUrl && !isEmail && !isPhone) {
      return 'Enter a valid email, phone number, or link (https://...)';
    }
    return null;
  }

  void _addCustomSkill() {
    final skill = _customSkillCtrl.text.trim();
    if (skill.isEmpty) return;
    if (_selectedSkills.contains(skill)) return;
    setState(() {
      _selectedSkills.add(skill);
      _customSkillCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and description.')),
      );
      return;
    }

    final contactError = _validateContactInfo(_contactCtrl.text);
    if (contactError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contactError)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;

      if (_isEditing) {
        final original = widget.editPost!;
        final updated = TeamUpPost(
          id: original.id,
          authorUid: original.authorUid,
          authorName: original.authorName,
          authorAvatarUrl: original.authorAvatarUrl,
          authorBranch: original.authorBranch,
          authorYear: original.authorYear,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          skillsNeeded: _selectedSkills,
          contactInfo: _contactCtrl.text.trim(),
          linkedHackathon: _hackathonCtrl.text.trim().isEmpty ? null : _hackathonCtrl.text.trim(),
          isOpen: original.isOpen,
          createdAt: original.createdAt,
        );

        await ref.read(teamUpServiceProvider).updatePost(updated);

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated!'), backgroundColor: AppColors.success),
          );
        }
        return;
      }

      final post = TeamUpPost(
        id: const Uuid().v4(),
        authorUid: user.uid,
        authorName: user.name,
        authorAvatarUrl: user.avatarUrl,
        authorBranch: user.branch,
        authorYear: user.year,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        skillsNeeded: _selectedSkills,
        contactInfo: _contactCtrl.text.trim(),
        linkedHackathon: _hackathonCtrl.text.trim().isEmpty ? null : _hackathonCtrl.text.trim(),
        isOpen: true,
        createdAt: DateTime.now(),
      );

      await ref.read(teamUpServiceProvider).createPost(post);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Team Request' : 'Post Team Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const _Label('Title *'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Looking for Flutter Developer'),
            ),
            const SizedBox(height: 16),

            // Description
            const _Label('Description *'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'What are you building? What kind of teammate do you need?'),
            ),
            const SizedBox(height: 16),

            // Skills needed
            const _Label('Skills Needed'),
            const SizedBox(height: 6),

            // Preset skills
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppConstants.skillTags.map((s) {
                final selected = _selectedSkills.contains(s);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedSkills.remove(s);
                    } else {
                      _selectedSkills.add(s);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.ink, width: 2),
                      boxShadow: selected ? AppShadows.small : [],
                    ),
                    child: Text(s, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Custom skill input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customSkillCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a custom skill...',
                      prefixIcon: Icon(Icons.add_circle_outline, size: 18),
                    ),
                    onSubmitted: (_) => _addCustomSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addCustomSkill,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),

            // Show custom skills added
            if (_selectedSkills.any((s) => !AppConstants.skillTags.contains(s))) ...[
              const SizedBox(height: 10),
              const Text('Custom skills added:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedSkills
                    .where((s) => !AppConstants.skillTags.contains(s))
                    .map((s) => GestureDetector(
                          onTap: () => setState(() => _selectedSkills.remove(s)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLighter,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(s, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              const Icon(Icons.close, size: 12, color: AppColors.primary),
                            ]),
                          ),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Contact info
            const _Label('Contact Info *'),
            const SizedBox(height: 6),
            TextField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                hintText: 'Email, phone, or LinkedIn URL',
                helperText: 'Must be a valid email, phone number, or https:// link',
              ),
            ),
            const SizedBox(height: 16),

            // Linked hackathon
            const _Label('Linked Hackathon (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _hackathonCtrl,
              decoration: const InputDecoration(hintText: 'e.g. HackKIET 4.0'),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: _isEditing ? 'Save Changes' : 'Post Request',
                onTap: _submit,
                isLoading: _loading,
                height: 52,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
  }
}