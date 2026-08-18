import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';
import '../../../core/constants/app_constants.dart';

/// Full-page screen to edit an existing club's details.
///
/// Used by:
///  - Super Admin panel: can open this for ANY club (pick from a list first).
///  - Club Admin panel: can only ever open this for the single club they manage.
///
/// Both cases reuse this exact screen — the caller decides which [club] is
/// passed in, and this screen never lets you change which club you're editing.
class EditClubScreen extends ConsumerStatefulWidget {
  final ClubModel club;

  const EditClubScreen({super.key, required this.club});

  @override
  ConsumerState<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends ConsumerState<EditClubScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _domainsCtrl;
  late final TextEditingController _headNameCtrl;
  late final TextEditingController _headEmailCtrl;
  late final TextEditingController _logoCtrl;
  late final TextEditingController _bannerCtrl;
  late final TextEditingController _igCtrl;
  late final TextEditingController _liCtrl;
  late final TextEditingController _ghCtrl;
  late final TextEditingController _webCtrl;
  final _newAchievementCtrl = TextEditingController();

  late String _category;
  late String _recruitmentStatus;
  late List<String> _achievements;
  late List<Map<String, TextEditingController>> _members;

  bool _isLoading = false;

  String _socialUrl(String platform) {
    try {
      return widget.club.socialLinks.firstWhere((s) => s.platform == platform).url;
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    final club = widget.club;

    _nameCtrl = TextEditingController(text: club.name);
    _descCtrl = TextEditingController(text: club.description);
    _domainsCtrl = TextEditingController(text: club.domains.join(', '));
    _headNameCtrl = TextEditingController(text: club.coreTeam.headName);
    _headEmailCtrl = TextEditingController(text: club.coreTeam.headEmail);
    _logoCtrl = TextEditingController(text: club.logoUrl ?? '');
    _bannerCtrl = TextEditingController(text: club.bannerUrl ?? '');
    _igCtrl = TextEditingController(text: _socialUrl('instagram'));
    _liCtrl = TextEditingController(text: _socialUrl('linkedin'));
    _ghCtrl = TextEditingController(text: _socialUrl('github'));
    _webCtrl = TextEditingController(text: _socialUrl('website'));

    _category = AppConstants.clubCategories.contains(club.category)
        ? club.category
        : AppConstants.clubCategories.first;
    _recruitmentStatus = club.recruitmentStatus;
    _achievements = List<String>.from(club.achievements);
    _members = club.coreTeam.members
        .map((m) => {
              'name': TextEditingController(text: m.name),
              'role': TextEditingController(text: m.role),
            })
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _domainsCtrl.dispose();
    _headNameCtrl.dispose();
    _headEmailCtrl.dispose();
    _logoCtrl.dispose();
    _bannerCtrl.dispose();
    _igCtrl.dispose();
    _liCtrl.dispose();
    _ghCtrl.dispose();
    _webCtrl.dispose();
    _newAchievementCtrl.dispose();
    for (final m in _members) {
      m['name']!.dispose();
      m['role']!.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final domains = _domainsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final socialLinks = <Map<String, String>>[];
      if (_igCtrl.text.trim().isNotEmpty) {
        socialLinks.add({'platform': 'instagram', 'url': _igCtrl.text.trim()});
      }
      if (_liCtrl.text.trim().isNotEmpty) {
        socialLinks.add({'platform': 'linkedin', 'url': _liCtrl.text.trim()});
      }
      if (_ghCtrl.text.trim().isNotEmpty) {
        socialLinks.add({'platform': 'github', 'url': _ghCtrl.text.trim()});
      }
      if (_webCtrl.text.trim().isNotEmpty) {
        socialLinks.add({'platform': 'website', 'url': _webCtrl.text.trim()});
      }

      final members = _members
          .map((m) => {
                'name': m['name']!.text.trim(),
                'role': m['role']!.text.trim(),
                'avatarUrl': null,
              })
          .where((m) => (m['name'] as String).isNotEmpty)
          .toList();

      await ref.read(adminServiceProvider).updateClubInfo(widget.club.id, {
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'description': _descCtrl.text.trim(),
        'domains': domains,
        'recruitmentStatus': _recruitmentStatus,
        'logoUrl': _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
        'bannerUrl': _bannerCtrl.text.trim().isEmpty ? null : _bannerCtrl.text.trim(),
        'socialLinks': socialLinks,
        'achievements': _achievements,
        'coreTeam': {
          'headName': _headNameCtrl.text.trim(),
          'headAvatarUrl': widget.club.coreTeam.headAvatarUrl,
          'headEmail': _headEmailCtrl.text.trim(),
          'members': members,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club updated!'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update club: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit ${widget.club.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Basic Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Club name',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Club name is required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                items: AppConstants.clubCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _domainsCtrl,
                decoration: const InputDecoration(
                  hintText: 'Domains, comma separated (e.g. AI, Web Dev, App Dev)',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Recruitment:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text(
                      'Closed',
                      style: TextStyle(
                        color: _recruitmentStatus == 'closed' ? AppColors.primary : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _recruitmentStatus == 'closed',
                    onSelected: (_) => setState(() => _recruitmentStatus = 'closed'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      'Open',
                      style: TextStyle(
                        color: _recruitmentStatus == 'open' ? AppColors.primary : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _recruitmentStatus == 'open',
                    onSelected: (_) => setState(() => _recruitmentStatus = 'open'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const _SectionLabel('President / Core Team'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _headNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'President name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _headEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'president@kiet.edu',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return v.contains('@') ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 12),
              const Text('Team Members',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ..._members.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Member ${e.key + 1}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                e.value['name']!.dispose();
                                e.value['role']!.dispose();
                                _members.removeAt(e.key);
                              }),
                              child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: e.value['name'],
                          decoration: const InputDecoration(hintText: 'Name'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: e.value['role'],
                          decoration: const InputDecoration(hintText: 'Role'),
                        ),
                      ],
                    ),
                  )),
              GestureDetector(
                onTap: () => setState(() => _members.add({
                      'name': TextEditingController(),
                      'role': TextEditingController(),
                    })),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text('Add Member', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const _SectionLabel('Media'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logoCtrl,
                decoration: const InputDecoration(
                  hintText: 'Logo image URL',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bannerCtrl,
                decoration: const InputDecoration(
                  hintText: 'Banner image URL (optional)',
                  prefixIcon: Icon(Icons.panorama_outlined),
                ),
              ),

              const SizedBox(height: 24),
              const _SectionLabel('Social Links'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _igCtrl,
                decoration: const InputDecoration(
                  hintText: 'Instagram URL',
                  prefixIcon: Icon(Icons.camera_alt_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _liCtrl,
                decoration: const InputDecoration(
                  hintText: 'LinkedIn URL',
                  prefixIcon: Icon(Icons.business_center_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ghCtrl,
                decoration: const InputDecoration(
                  hintText: 'GitHub URL',
                  prefixIcon: Icon(Icons.code_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _webCtrl,
                decoration: const InputDecoration(
                  hintText: 'Website URL',
                  prefixIcon: Icon(Icons.language_outlined),
                ),
              ),

              const SizedBox(height: 24),
              const _SectionLabel('Achievements'),
              const SizedBox(height: 12),
              ..._achievements.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_outlined, size: 14, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
                        GestureDetector(
                          onTap: () => setState(() => _achievements.removeAt(e.key)),
                          child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newAchievementCtrl,
                      decoration: const InputDecoration(hintText: 'Add achievement...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_newAchievementCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _achievements.add(_newAchievementCtrl.text.trim());
                          _newAchievementCtrl.clear();
                        });
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              GradientButton(
                label: 'Save Changes',
                isLoading: _isLoading,
                onTap: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }
}