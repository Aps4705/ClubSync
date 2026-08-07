import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const NotificationSettingsScreen({super.key, required this.user});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  late bool _masterEnabled;
  late Map<String, bool> _prefs;
  bool _saving = false;

 
  late bool _savedMasterEnabled;
  late Map<String, bool> _savedPrefs;

  static const _options = [
    ('recruitments', 'Recruitment alerts', 'New recruitment drives from clubs you follow', Icons.person_add_outlined),
    ('events', 'Event reminders', 'Upcoming events and registration deadlines', Icons.calendar_today_outlined),
    ('hackathons', 'Hackathon updates', 'New hackathons and important deadlines', Icons.emoji_events_outlined),
    ('announcements', 'Club announcements', 'Posts and updates from followed clubs', Icons.campaign_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _masterEnabled = widget.user.notificationsEnabled;
    _prefs = Map.from(widget.user.notificationPrefs);
    for (final o in _options) {
      _prefs.putIfAbsent(o.$1, () => true);
    }
    _savedMasterEnabled = _masterEnabled;
    _savedPrefs = Map.from(_prefs);
  }

  bool get _hasUnsavedChanges {
    if (_masterEnabled != _savedMasterEnabled) return true;
    if (_prefs.length != _savedPrefs.length) return true;
    for (final entry in _prefs.entries) {
      if (_savedPrefs[entry.key] != entry.value) return true;
    }
    return false;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).updateNotificationSettings(
        widget.user.uid, _masterEnabled, _prefs,
      );
      if (mounted) {
        setState(() {
          _savedMasterEnabled = _masterEnabled;
          _savedPrefs = Map.from(_prefs);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved'), backgroundColor: AppColors.success),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved notification settings. If you leave now, your changes will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscardChanges();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Notification Settings'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('All Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('Master switch for all alerts', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
              Switch(
                value: _masterEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _masterEnabled = v),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Notification types', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
            child: Column(
              children: _options.asMap().entries.map((entry) {
                final i = entry.key;
                final (key, label, subtitle, icon) = entry.value;
                return Column(children: [
                  Opacity(
                    opacity: _masterEnabled ? 1 : 0.4,
                    child: IgnorePointer(
                      ignoring: !_masterEnabled,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(10)),
                            child: Icon(icon, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ]),
                          ),
                          Switch(
                            value: _prefs[key] ?? true,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => setState(() => _prefs[key] = v),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  if (i != _options.length - 1) const Divider(height: 1, indent: 64),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class NotificationSettingsScreenWrapper extends ConsumerWidget {
  const NotificationSettingsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return NotificationSettingsScreen(user: user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}