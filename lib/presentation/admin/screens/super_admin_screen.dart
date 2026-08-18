import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';
import '../../../core/constants/app_constants.dart';
import 'edit_club_screen.dart';

final _allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminServiceProvider).getAllUsers();
});

final _allClubsForAdminProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(clubsServiceProvider).getClubs();
});

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser?.role != 'super_admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Super Admin')),
        body: const EmptyState(
          title: 'Access Denied',
          subtitle: 'Only super admins can access this screen.',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Super Admin'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
tabs: const [
            Tab(text: 'Add Club'),
            Tab(text: 'Edit Clubs'),
            Tab(text: 'Assign Admins'),
            Tab(text: 'Club Logos'),
            Tab(text: 'Club Contacts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AddClubTab(),
          _EditClubsTab(),
          _AssignAdminsTab(),
          _ClubLogosTab(),
          _ClubContactsTab(),
        ],
      ),
    );
  }
}

// Assign Admins Tab 

class _AssignAdminsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_allUsersProvider);
    final clubsAsync = ref.watch(_allClubsForAdminProvider);

    return usersAsync.when(
      data: (users) => clubsAsync.when(
        data: (clubs) {
          final admins = users.where((u) => u.role == 'club_admin').toList();
          final students = users.where((u) => u.role == 'student').toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Current admins
              if (admins.isNotEmpty) ...[
                const Text('Current Club Admins',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ...admins.map((u) {
                  final club = clubs.where((c) => c.id == u.managedClubId).firstOrNull;
                  return _UserAdminCard(
                    user: u,
                    club: club,
                    isAdmin: true,
                    clubs: clubs,
                    onRemove: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Admin'),
                          content: Text('Remove ${u.name} as club admin?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(adminServiceProvider).removeClubAdmin(u.uid);
                      }
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Students — assign admin
              const Text('Students',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              if (students.isEmpty)
                const _EmptyCard(text: 'No students found.')
              else
                ...students.map((u) => _UserAdminCard(
                      user: u,
                      isAdmin: false,
                      clubs: clubs,
                      onAssign: (clubId) async {
                        await ref.read(adminServiceProvider).assignClubAdmin(u.uid, clubId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${u.name} is now admin of ${clubs.firstWhere((c) => c.id == clubId).name}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _UserAdminCard extends StatelessWidget {
  final UserModel user;
  final ClubModel? club;
  final bool isAdmin;
  final List<ClubModel> clubs;
  final VoidCallback? onRemove;
  final Function(String clubId)? onAssign;

  const _UserAdminCard({
    required this.user,
    required this.isAdmin,
    required this.clubs,
    this.club,
    this.onRemove,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
        border: isAdmin ? Border.all(color: AppColors.primary.withValues(alpha: 0.2)) : null,
      ),
      child: Row(
        children: [
          ClubAvatar(imageUrl: user.avatarUrl, name: user.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                if (isAdmin && club != null) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('Admin — ${club!.name}',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ]),
                ],
              ],
            ),
          ),
          if (isAdmin)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )
          else
            GestureDetector(
              onTap: () => _showAssignDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppShadows.elevated,
                ),
                child: const Text('Make Admin', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    String? selectedClubId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Assign ${user.name} as Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select club:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedClubId,
                decoration: const InputDecoration(hintText: 'Choose a club'),
                items: clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => selectedClubId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: selectedClubId == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      onAssign!(selectedClubId!);
                    },
              child: const Text('Assign', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

//Club Logos Tab

class _ClubLogosTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(_allClubsForAdminProvider);

    return clubsAsync.when(
      data: (clubs) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: clubs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ClubLogoCard(club: clubs[i]),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ClubLogoCard extends ConsumerWidget {
  final ClubModel club;
  const _ClubLogoCard({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          ClubAvatar(imageUrl: club.logoUrl, name: club.name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(club.category, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showLogoDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Edit Logo', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoDialog(BuildContext context, WidgetRef ref) {
    final logoCtrl = TextEditingController(text: club.logoUrl ?? '');
    final bannerCtrl = TextEditingController(text: club.bannerUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${club.name} — Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste image URLs (use Imgur, Google Drive, etc.)',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: logoCtrl,
              decoration: const InputDecoration(
                hintText: 'Logo image URL',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bannerCtrl,
              decoration: const InputDecoration(
                hintText: 'Banner image URL (optional)',
                prefixIcon: Icon(Icons.panorama_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminServiceProvider).updateClubMedia(
                club.id,
                logoUrl: logoCtrl.text.trim().isEmpty ? null : logoCtrl.text.trim(),
                bannerUrl: bannerCtrl.text.trim().isEmpty ? null : bannerCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Club media updated!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}
// Club Contacts Tab

class _ClubContactsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(_allClubsForAdminProvider);

    return clubsAsync.when(
      data: (clubs) {
        if (clubs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: _EmptyCard(text: 'No clubs found.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: clubs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ClubContactCard(club: clubs[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ClubContactCard extends ConsumerWidget {
  final ClubModel club;
  const _ClubContactCard({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEmail = club.coreTeam.headEmail.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          ClubAvatar(imageUrl: club.logoUrl, name: club.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  club.coreTeam.headName.isEmpty ? 'No president set' : club.coreTeam.headName,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  hasEmail ? club.coreTeam.headEmail : 'No email added',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: hasEmail ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEmailDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasEmail ? 'Edit' : 'Add Email',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController(text: club.coreTeam.headEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${club.name} — President Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This email is shown to students under Help & Support so they can reach the club president directly.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'president@kiet.edu',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isNotEmpty && !email.contains('@')) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email.'), backgroundColor: AppColors.error),
                );
                return;
              }
              Navigator.pop(ctx);
              
              await ref.read(adminServiceProvider).updateClubInfo(club.id, {
                'coreTeam.headEmail': email,
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('President email updated!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
// Edit Clubs Tab — super admin can edit ANY club's full details

class _EditClubsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(_allClubsForAdminProvider);

    return clubsAsync.when(
      data: (clubs) {
        if (clubs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: _EmptyCard(text: 'No clubs found.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: clubs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _EditClubCard(club: clubs[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _EditClubCard extends StatelessWidget {
  final ClubModel club;
  const _EditClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          ClubAvatar(imageUrl: club.logoUrl, name: club.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(club.category, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditClubScreen(club: club)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// Add Club Tab

class _AddClubTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddClubTab> createState() => _AddClubTabState();
}

class _AddClubTabState extends ConsumerState<_AddClubTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _domainsCtrl = TextEditingController();
  final _headNameCtrl = TextEditingController();
  final _headEmailCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _bannerCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _liCtrl = TextEditingController();
  final _ghCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  final _newAchievementCtrl = TextEditingController();

  String _category = AppConstants.clubCategories.first;
  String _recruitmentStatus = 'closed';
  final List<String> _achievements = [];
  final List<Map<String, TextEditingController>> _members = [];
  bool _isLoading = false;

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

      await ref.read(adminServiceProvider).createClub(
            name: _nameCtrl.text.trim(),
            category: _category,
            description: _descCtrl.text.trim(),
            domains: domains,
            headName: _headNameCtrl.text.trim(),
            headEmail: _headEmailCtrl.text.trim(),
            recruitmentStatus: _recruitmentStatus,
            logoUrl: _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
            bannerUrl: _bannerCtrl.text.trim().isEmpty ? null : _bannerCtrl.text.trim(),
            socialLinks: socialLinks,
            achievements: _achievements,
            members: members,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club created!'), backgroundColor: AppColors.success),
        );
        _formKey.currentState!.reset();
        _nameCtrl.clear();
        _descCtrl.clear();
        _domainsCtrl.clear();
        _headNameCtrl.clear();
        _headEmailCtrl.clear();
        _logoCtrl.clear();
        _bannerCtrl.clear();
        _igCtrl.clear();
        _liCtrl.clear();
        _ghCtrl.clear();
        _webCtrl.clear();
        _newAchievementCtrl.clear();
        setState(() {
          _category = AppConstants.clubCategories.first;
          _recruitmentStatus = 'closed';
          _achievements.clear();
          for (final m in _members) {
            m['name']!.dispose();
            m['role']!.dispose();
          }
          _members.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create club: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Club',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
            const SizedBox(height: 20),
            const Text('President (optional — can add later)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
            const Text('Media',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
            const Text('Social Links',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
            const Text('Achievements',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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

            const SizedBox(height: 24),
            GradientButton(
              label: 'Create Club',
              isLoading: _isLoading,
              onTap: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}