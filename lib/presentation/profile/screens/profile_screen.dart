import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';



class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        return _ProfileView(user: user);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ProfileView extends ConsumerStatefulWidget {
  final UserModel user;
  const _ProfileView({required this.user});

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  late bool _notificationsEnabled;
  late Map<String, bool> _prefs;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.user.notificationsEnabled;
    _prefs = Map.from(widget.user.notificationPrefs);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isAdmin = user.role == 'club_admin' || user.role == 'super_admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue gradient header
            Container(
              decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        children: [
                          const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                          const SizedBox(height: 20),
                          ClubAvatar(imageUrl: user.avatarUrl, name: user.name, size: 80),
                          const SizedBox(height: 12),
                          Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                          const SizedBox(height: 3),
                          Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _WhitePill(user.branch),
                              const SizedBox(width: 8),
                              _WhitePill(user.year),
                              const SizedBox(width: 8),
                              _WhitePill(isAdmin ? 'Admin' : 'Student', accent: isAdmin),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Stats row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    Expanded(child: _StatBox(icon: Icons.groups_2_outlined, value: '${user.followedClubs.length}', label: 'Following')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox(icon: Icons.event_available_outlined, value: '${user.registeredEvents.length}', label: 'Registered')),
                    const SizedBox(width: 12),
                    const Expanded(child: _StatBox(icon: Icons.post_add_outlined, value: '0', label: 'Posts')),
                  ]),
                ),

                const SizedBox(height: 20),

                // Admin dashboard
                if (isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: GestureDetector(
                      onTap: () => context.push('/admin'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.elevated,
                        ),
                        child: const Row(children: [
                          Icon(Icons.dashboard_outlined, color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('Manage club, events & analytics', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ])),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                        ]),
                      ),
                    ),
                  ),
                  
                ],
                if (user.role == 'super_admin') ...[
  Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: GestureDetector(
      onTap: () => context.push('/super-admin'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.elevated,
        ),
        child: const Row(children: [
          Icon(Icons.shield_outlined, color: Colors.white, size: 22),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Super Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Text('Assign admins, manage all clubs', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 14),
        ]),
      ),
    ),
  ),
],

                // My Activity
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _SectionLabel('My Activity'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
                    child: Column(children: [
_ActivityTile(
  icon: Icons.groups_2_outlined,
  label: 'Followed Clubs',
  trailing: '${user.followedClubs.length}',
  onTap: () => context.push('/profile/followed-clubs'), // ← was () {}
),
const Divider(height: 1, indent: 52),
_ActivityTile(
  icon: Icons.calendar_today_outlined,
  label: 'Registered Events',
  trailing: '${user.registeredEvents.length}',
  onTap: () => context.push('/profile/registered-events'),
),

                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // Settings
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _SectionLabel('Settings'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
child: Column(children: [
  _ActivityTile(
    icon: Icons.person_outline_rounded,
    label: 'Edit Profile',
    trailing: 'Name, Branch, Year',
    onTap: () => context.push('/profile/edit'),
  ),
  const Divider(height: 1, indent: 52),
  _ActivityTile(
    icon: Icons.notifications_outlined,
    label: 'Notification Settings',
    trailing: _notificationsEnabled ? 'On' : 'Off',
    onTap: () => context.push('/profile/notifications'),
  ),
  const Divider(height: 1, indent: 52),

  const Divider(height: 1, indent: 52),
 _ActivityTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () => context.push('/help-support')),
  const Divider(height: 1, indent: 52),
  _ActivityTile(icon: Icons.logout_rounded, label: 'Sign Out', onTap: _signOut, isDestructive: true),
]),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('ClubSync · KIET  v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String label;
  final bool accent;
  const _WhitePill(this.label, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: accent ? AppColors.primary : Colors.white,
      )),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBox({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.card),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActivityTile({
    required this.icon, required this.label, required this.onTap,
    this.trailing, this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isDestructive ? AppColors.errorBg : AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: isDestructive ? AppColors.error : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
          ))),
          if (trailing != null) ...[
            Text(trailing!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(width: 6),
          ],
          if (!isDestructive) const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}