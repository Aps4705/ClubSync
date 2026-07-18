import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';

final _followedClubsProvider = StreamProvider<List<ClubModel>>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  if (user == null || user.followedClubs.isEmpty) {
    yield [];
    return;
  }
  // Query only the followed clubs directly instead of fetching the entire
  // clubs collection and filtering client-side.
  yield* ref.watch(clubsServiceProvider).getClubsByIds(user.followedClubs);
});

class FollowedClubsScreen extends ConsumerWidget {
  const FollowedClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final clubsAsync = ref.watch(_followedClubsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Followed Clubs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : user.followedClubs.isEmpty
              ? const EmptyState(
                  title: 'No clubs followed',
                  subtitle: 'Clubs you follow will appear here. Go explore!',
                  icon: Icons.groups_2_outlined,
                )
              : clubsAsync.when(
                  data: (followed) {
                    // clubsAsync now already contains only the followed
                    // clubs (fetched via getClubsByIds), no extra filter needed.
                    if (followed.isEmpty) {
                      return const EmptyState(
                        title: 'No clubs followed',
                        subtitle: 'Clubs you follow will appear here.',
                        icon: Icons.groups_2_outlined,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: followed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final club = followed[i];
                        return GestureDetector(
                          onTap: () => context.push('/clubs/${club.id}'),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppShadows.card,
                            ),
                            child: Row(
                              children: [
                                ClubAvatar(imageUrl: club.logoUrl, name: club.name, size: 52),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(club.name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        if (club.isVerified)
                                          const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                                      ]),
                                      const SizedBox(height: 4),
                                      CategoryBadge(label: club.category),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.people_outline, size: 13, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text('${club.followerCount} followers',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ]),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Unfollow button
                                GestureDetector(
                                  onTap: () async {
                                    await ref.read(clubsServiceProvider).unfollowClub(user.uid, club.id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text('Unfollow',
                                        style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 80),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
    );
  }
}