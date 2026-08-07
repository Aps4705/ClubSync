import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';

final _allClubsForHelpProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(clubsServiceProvider).getClubs();
});

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(_allClubsForHelpProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: clubsAsync.when(
        data: (clubs) {
          final withEmail = clubs.where((c) => c.coreTeam.headEmail.trim().isNotEmpty).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Have a question about a specific club? Reach out to its president directly.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Club Presidents',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              if (withEmail.isEmpty)
                const _EmptyCard(text: 'No club contact emails have been added yet.')
              else
                ...withEmail.map((c) => _PresidentContactTile(club: c)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PresidentContactTile extends StatelessWidget {
  final ClubModel club;
  const _PresidentContactTile({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                const SizedBox(height: 2),
                Text(
                  club.coreTeam.headName.isEmpty ? 'President' : '${club.coreTeam.headName} · President',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  club.coreTeam.headEmail,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: club.coreTeam.headEmail));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email copied to clipboard'), backgroundColor: AppColors.success),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
            ),
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