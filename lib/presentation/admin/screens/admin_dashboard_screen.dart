import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';
import 'edit_club_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser == null ||
        (currentUser.role != 'club_admin' && currentUser.role != 'super_admin')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const EmptyState(
          title: 'Access Denied',
          subtitle: 'Only club admins can access this dashboard.',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }

    final clubId = currentUser.managedClubId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Post Content'),
            Tab(text: 'Manage'),
          ],
        ),
      ),
      body: clubId.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  title: 'No club assigned',
                  subtitle: 'Ask the super admin to assign you to a club.',
                  icon: Icons.groups_2_outlined,
                ),
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _AnalyticsTab(clubId: clubId),
                _PostContentTab(user: currentUser, clubId: clubId),
                _ManageTab(user: currentUser, clubId: clubId),
              ],
            ),
    );
  }
}

// Analytics Tab 
class _AnalyticsTab extends ConsumerWidget {
  final String clubId;
  const _AnalyticsTab({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_realAnalyticsProvider(clubId));
    final clubAsync = ref.watch(_clubForAdminProvider(clubId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Club Performance', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Live data from Firestore', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          analyticsAsync.when(
            data: (data) => Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _MetricTile(
                      label: 'Followers',
                      value: '${data['followers'] ?? 0}',
                      icon: Icons.people_outline,
                      color: AppColors.accent,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricTile(
                      label: 'Domains',
                      value: '${data['domains'] ?? 0}',
                      icon: Icons.category_outlined,
                      color: AppColors.secondary,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _MetricTile(
                      label: 'Achievements',
                      value: '${data['achievements'] ?? 0}',
                      icon: Icons.emoji_events_outlined,
                      color: AppColors.warning,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricTile(
                      label: 'Recruitment',
                      value: (data['recruitmentStatus'] ?? 'closed') == 'open' ? 'Open' : 'Closed',
                      icon: Icons.person_add_outlined,
                      color: (data['recruitmentStatus'] ?? 'closed') == 'open'
                          ? AppColors.success
                          : AppColors.error,
                    )),
                  ],
                ),
                const SizedBox(height: 20),
                clubAsync.when(
                  data: (club) {
                    if (club == null) return const SizedBox();
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Club Info', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Name', value: club.name),
                          _InfoRow(label: 'Category', value: club.category),
                          _InfoRow(label: 'Status', value: club.isVerified ? 'Verified ✓' : 'Not Verified'),
                          _InfoRow(label: 'Members', value: '${club.followerCount} followers'),
                        ],
                      ),
                    );
                  },
                  loading: () => const ShimmerBox(width: double.infinity, height: 120),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
            loading: () => Column(
              children: List.generate(4, (i) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(width: double.infinity, height: 80),
              )),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

//Post Content Tab

class _PostContentTab extends ConsumerWidget {
  final UserModel user;
  final String clubId;
  const _PostContentTab({required this.user, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(_clubForAdminProvider(clubId));

    return clubAsync.when(
      data: (club) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Content', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Post updates for ${club?.name ?? 'your club'}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            ..._ContentType.all.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => _showCreateSheet(context, ref, type, club),
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                      color: type.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(type.icon, color: type.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(type.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(type.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                ]),
              ),
            )),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref, _ContentType type, ClubModel? club) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSheet(type: type, user: user, club: club, clubId: clubId),
    );
  }
}

class _ContentType {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String key;

  const _ContentType({required this.title, required this.subtitle, required this.icon, required this.color, required this.key});

  static const all = [
    _ContentType(title: 'Announcement', subtitle: 'Post updates and news to followers', icon: Icons.campaign_outlined, color: AppColors.info, key: 'announcement'),
    _ContentType(title: 'Open Recruitment', subtitle: 'Invite students to join your club', icon: Icons.person_add_outlined, color: AppColors.success, key: 'recruitment'),
    _ContentType(title: 'New Event', subtitle: 'Create workshops, talks, or competitions', icon: Icons.event_outlined, color: AppColors.accent, key: 'event'),
  ];
}

class _CreateSheet extends ConsumerStatefulWidget {
  final _ContentType type;
  final UserModel user;
  final ClubModel? club;
  final String clubId;

  const _CreateSheet({required this.type, required this.user, required this.club, required this.clubId});

  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _registrationLinkCtrl = TextEditingController();
String _eventType = 'workshop';
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  @override
  void dispose() {
    _registrationLinkCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _venueCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

Future<void> _submit() async {
  if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields.')),
    );
    return;
  }
  if (widget.type.key == 'event' && _selectedDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select an event date.')),
    );
    return;
  }

  setState(() => _loading = true);
  try {
    final admin = ref.read(adminServiceProvider);
    final clubName = widget.club?.name ?? widget.user.name;

    if (widget.type.key == 'announcement') {
      await admin.createAnnouncement(AnnouncementModel(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        clubId: widget.clubId,
        clubName: clubName,
        isCampusWide: true,
        priority: 'normal',
        createdAt: DateTime.now(),
      ));
    } else if (widget.type.key == 'recruitment') {
      await admin.createRecruitment(RecruitmentModel(
        id: const Uuid().v4(),
        clubId: widget.clubId,
        clubName: clubName,
        title: _titleCtrl.text.trim(),
        description: _bodyCtrl.text.trim(),
        applyLink: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
        deadline: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
        status: 'open',
        createdAt: DateTime.now(),
      ));
    } else if (widget.type.key == 'event') {
      await admin.createEvent(EventModel(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        clubId: widget.clubId,
        clubName: clubName,
        description: _bodyCtrl.text.trim(),
        date: _selectedDate!,
        venue: _venueCtrl.text.trim().isEmpty ? 'TBA' : _venueCtrl.text.trim(),
        registrationLink: _registrationLinkCtrl.text.trim().isEmpty
            ? null
            : _registrationLinkCtrl.text.trim(),
        status: 'upcoming',
        type: _eventType,
        createdAt: DateTime.now(),
      ));
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.type.title} posted!'),
          backgroundColor: AppColors.success,
        ),
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
    return Container(
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: AppColors.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('New ${widget.type.title}', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 20),

            // Title
            const Text('Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Enter title')),
            const SizedBox(height: 12),

            // Body
            Text(widget.type.key == 'announcement' ? 'Message *' : 'Description *',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(controller: _bodyCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Write details here...')),
            const SizedBox(height: 12),

            // Event-specific fields
if (widget.type.key == 'event') ...[
  const Text('Venue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
  const SizedBox(height: 6),
  TextField(controller: _venueCtrl, decoration: const InputDecoration(hintText: 'e.g. Main Auditorium')),
  const SizedBox(height: 12),

  const Text('Event Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
  const SizedBox(height: 8),
  StatefulBuilder(
    builder: (ctx, setLocal) => Wrap(
      spacing: 8, runSpacing: 8,
      children: ['workshop', 'seminar', 'hackathon', 'cultural', 'sports', 'competition'].map((type) {
        final selected = _eventType == type;
        return GestureDetector(
          onTap: () => setState(() => _eventType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              color: selected ? null : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: selected ? Colors.transparent : const Color(0xFFDDE8F5)),
            ),
            child: Text(
              type[0].toUpperCase() + type.substring(1),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textSecondary),
            ),
          ),
        );
      }).toList(),
    ),
  ),
  const SizedBox(height: 12),

  const Text('Registration Link (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
  const SizedBox(height: 6),
  TextField(
    controller: _registrationLinkCtrl,
    decoration: const InputDecoration(hintText: 'https://forms.google.com/...'),
  ),
  const SizedBox(height: 12),

  const Text('Date *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
  const SizedBox(height: 6),
  GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(
          _selectedDate == null
              ? 'Select date'
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          style: TextStyle(fontSize: 14, color: _selectedDate == null ? AppColors.textMuted : AppColors.textPrimary),
        ),
      ]),
    ),
  ),
  const SizedBox(height: 12),
],

            // Recruitment-specific
            if (widget.type.key == 'recruitment') ...[
              const Text('Apply Link (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(controller: _linkCtrl, decoration: const InputDecoration(hintText: 'https://forms.google.com/...')),
              const SizedBox(height: 12),
              const Text('Deadline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate == null ? 'Select deadline' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(fontSize: 14, color: _selectedDate == null ? AppColors.textMuted : AppColors.textPrimary),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: GradientButton(label: 'Publish', onTap: _submit, isLoading: _loading, height: 50),
            ),
          ],
        ),
      ),
    );
  }
}

//Manage Tab 

class _ManageTab extends ConsumerWidget {
  final UserModel user;
  final String clubId;
  const _ManageTab({required this.user, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(_clubForAdminProvider(clubId));

    return clubAsync.when(
      data: (club) {
        if (club == null) return const EmptyState(title: 'Club not found', subtitle: '', icon: Icons.error_outline);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Club Settings', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              const SizedBox(height: 20),
              Text('Posted Content', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _PostedContentSection(clubId: clubId),
              Text('Update ${club.name}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(4),
                child: Column(children: [
                  _ManageTile(
                    icon: Icons.tune_outlined, label: 'Edit Club Details',
                    subtitle: 'Full form — info, team, media, socials, achievements',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditClubScreen(club: club)),
                    ),
                  ),
                  _ManageTile(
                    icon: Icons.edit_outlined, label: 'Edit Club Info',
                    subtitle: 'Name, description, recruitment status',
                    color: AppColors.accent,
                    onTap: () => _showEditInfo(context, ref, club),
                  ),
                  _ManageTile(
                    icon: Icons.group_outlined, label: 'Manage Core Team',
                    subtitle: 'Update club head and team members',
                    color: AppColors.success,
                    onTap: () => _showEditTeam(context, ref, club),
                  ),
                  _ManageTile(
                    icon: Icons.link_outlined, label: 'Social Links',
                    subtitle: 'Instagram, LinkedIn, GitHub, Website',
                    color: AppColors.secondary,
                    onTap: () => _showEditSocials(context, ref, club),
                  ),
                  _ManageTile(
                    icon: Icons.workspace_premium_outlined, label: 'Achievements',
                    subtitle: 'Add or remove club achievements',
                    color: AppColors.warning,
                    onTap: () => _showEditAchievements(context, ref, club),
                  ),
                  _ManageTile(
                    icon: Icons.image_outlined, label: 'Club Logo & Banner',
                    subtitle: 'Update logo and banner image URLs',
                    color: AppColors.literary,
                    onTap: () => _showEditMedia(context, ref, club),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditInfo(BuildContext context, WidgetRef ref, ClubModel club) {
    final nameCtrl = TextEditingController(text: club.name);
    final descCtrl = TextEditingController(text: club.description);
    String status = club.recruitmentStatus;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => _Sheet(
          title: 'Edit Club Info',
          onSave: () async {
            await ref.read(adminServiceProvider).updateClubInfo(club.id, {
              'name': nameCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'recruitmentStatus': status,
            });
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Column(children: [
            _Field(label: 'Club Name', controller: nameCtrl),
            const SizedBox(height: 12),
            _Field(label: 'Description', controller: descCtrl, maxLines: 4),
            const SizedBox(height: 12),
            const Text('Recruitment Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              _StatusOption(label: 'Open', selected: status == 'open', color: AppColors.success, onTap: () => setState(() => status = 'open')),
              const SizedBox(width: 10),
              _StatusOption(label: 'Closed', selected: status == 'closed', color: AppColors.error, onTap: () => setState(() => status = 'closed')),
            ]),
          ]),
        ),
      ),
    );
  }

void _showEditTeam(BuildContext context, WidgetRef ref, ClubModel club) {
  final headNameCtrl = TextEditingController(text: club.coreTeam.headName);
  final members = club.coreTeam.members
      .map((m) => {
            'name': TextEditingController(text: m.name),
            'role': TextEditingController(text: m.role),
          })
      .toList();

  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => _Sheet(
        title: 'Core Team',
        onSave: () async {
          final updatedMembers = members.map((m) => {
            'name': (m['name'] as TextEditingController).text.trim(),
            'role': (m['role'] as TextEditingController).text.trim(),
            'avatarUrl': null,
          }).toList();

          await ref.read(adminServiceProvider).updateClubInfo(club.id, {
            'coreTeam': {
              'headName': headNameCtrl.text.trim(),
              'headAvatarUrl': club.coreTeam.headAvatarUrl,
              'headEmail': club.coreTeam.headEmail,
              'members': updatedMembers,
            }
          });
          if (ctx.mounted) Navigator.pop(ctx);
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Field(label: 'Club Head Name', controller: headNameCtrl),
          const SizedBox(height: 16),
          const Text('Team Members', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ...members.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              _Field(label: 'Name', controller: e.value['name'] as TextEditingController),
              const SizedBox(height: 8),
              _Field(label: 'Role', controller: e.value['role'] as TextEditingController),
            ]),
          )),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setLocal(() => members.add({
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
              child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, color: AppColors.primary, size: 16),
                SizedBox(width: 6),
                Text('Add Member', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ])),
            ),
          ),
        ]),
      ),
    ),
  );
}

  void _showEditSocials(BuildContext context, WidgetRef ref, ClubModel club) {
    String getUrl(String platform) {
      try { return club.socialLinks.firstWhere((s) => s.platform == platform).url; } catch (_) { return ''; }
    }

    final igCtrl = TextEditingController(text: getUrl('instagram'));
    final liCtrl = TextEditingController(text: getUrl('linkedin'));
    final ghCtrl = TextEditingController(text: getUrl('github'));
    final webCtrl = TextEditingController(text: getUrl('website'));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _Sheet(
        title: 'Social Links',
        onSave: () async {
          final links = <Map<String, String>>[];
          if (igCtrl.text.trim().isNotEmpty) links.add({'platform': 'instagram', 'url': igCtrl.text.trim()});
          if (liCtrl.text.trim().isNotEmpty) links.add({'platform': 'linkedin', 'url': liCtrl.text.trim()});
          if (ghCtrl.text.trim().isNotEmpty) links.add({'platform': 'github', 'url': ghCtrl.text.trim()});
          if (webCtrl.text.trim().isNotEmpty) links.add({'platform': 'website', 'url': webCtrl.text.trim()});
          await ref.read(adminServiceProvider).updateClubInfo(club.id, {'socialLinks': links});
          if (ctx.mounted) Navigator.pop(ctx);
        },
        child: Column(children: [
          _Field(label: 'Instagram URL', controller: igCtrl, hint: 'https://instagram.com/...'),
          const SizedBox(height: 10),
          _Field(label: 'LinkedIn URL', controller: liCtrl, hint: 'https://linkedin.com/...'),
          const SizedBox(height: 10),
          _Field(label: 'GitHub URL', controller: ghCtrl, hint: 'https://github.com/...'),
          const SizedBox(height: 10),
          _Field(label: 'Website URL', controller: webCtrl, hint: 'https://...'),
        ]),
      ),
    );
  }

  void _showEditAchievements(BuildContext context, WidgetRef ref, ClubModel club) {
    final achievements = List<String>.from(club.achievements);
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => _Sheet(
          title: 'Achievements',
          onSave: () async {
            await ref.read(adminServiceProvider).updateClubInfo(club.id, {'achievements': achievements});
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ...achievements.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.emoji_events_outlined, size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
                GestureDetector(
                  onTap: () => setState(() => achievements.removeAt(e.key)),
                  child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                ),
              ]),
            )),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Add achievement...'))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    setState(() { achievements.add(ctrl.text.trim()); ctrl.clear(); });
                  }
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showEditMedia(BuildContext context, WidgetRef ref, ClubModel club) {
    final logoCtrl = TextEditingController(text: club.logoUrl ?? '');
    final bannerCtrl = TextEditingController(text: club.bannerUrl ?? '');

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _Sheet(
        title: 'Logo & Banner',
        onSave: () async {
          await ref.read(adminServiceProvider).updateClubMedia(
            club.id,
            logoUrl: logoCtrl.text.trim().isEmpty ? null : logoCtrl.text.trim(),
            bannerUrl: bannerCtrl.text.trim().isEmpty ? null : bannerCtrl.text.trim(),
          );
          if (ctx.mounted) Navigator.pop(ctx);
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Paste image URLs from Imgur, Cloudinary, or any public image host.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          _Field(label: 'Logo URL', controller: logoCtrl, hint: 'https://i.imgur.com/...'),
          const SizedBox(height: 10),
          _Field(label: 'Banner URL', controller: bannerCtrl, hint: 'https://i.imgur.com/...'),
        ]),
      ),
    );
  }
}

// Shared sheet widget

class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  final Future<void> Function() onSave;

  const _Sheet({required this.title, required this.child, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: AppColors.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GradientButton(label: 'Save Changes', onTap: () async {
              await onSave();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved!'), backgroundColor: AppColors.success),
                );
              }
            }, height: 50),
          ),
        ]),
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ManageTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;

  const _Field({required this.label, required this.controller, this.maxLines = 1, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint ?? label)),
    ]);
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusOption({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? color : AppColors.textMuted,
          ))),
        ),
      ),
    );
  }
}

//Empty state card

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }
}

//Providers

final _realAnalyticsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, clubId) {
  return ref.watch(adminServiceProvider).getRealClubAnalytics(clubId);
});

final _clubForAdminProvider = StreamProvider.family<ClubModel?, String>((ref, clubId) {
  return ref.watch(clubsServiceProvider).getClub(clubId);
});
class _PostedContentSection extends ConsumerWidget {
  final String clubId;
  const _PostedContentSection({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(_clubEventsForAdminProvider(clubId));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const _EmptyCard(text: 'No events posted yet.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Events', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...events.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(e.venue, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ])),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Event'),
                        content: Text('Delete "${e.title}"? This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(adminServiceProvider).deleteEvent(e.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event deleted.'), backgroundColor: AppColors.success),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                  ),
                ),
              ]),
            )),
          ],
        );
      },
      loading: () => const ShimmerBox(width: double.infinity, height: 80),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

final _clubEventsForAdminProvider = StreamProvider.family<List<EventModel>, String>((ref, clubId) {
  return ref.watch(eventsServiceProvider).getClubEvents(clubId);
});