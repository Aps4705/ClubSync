import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';

final _selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final _searchQueryProvider = StateProvider<String>((ref) => '');
final _clubsProvider = StreamProvider.family<List<ClubModel>, String>((ref, category) {
  return ref.watch(clubsServiceProvider).getClubs(category: category == 'All' ? null : category);
});

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(_selectedCategoryProvider);
    final query = ref.watch(_searchQueryProvider);
    final clubs = ref.watch(_clubsProvider(category));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(_clubsProvider(category));
        },
        child: CustomScrollView(
        slivers: [
          // Blue header banner
          SliverToBoxAdapter(
            child: Container(
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
Row(
  children: [
    Text(
      'Clubs',
      style: Theme.of(context)
          .textTheme
          .headlineLarge
          ?.copyWith(
            color: Colors.white,
            fontSize: 24,
          ),
    ),
  ],
),
                      const SizedBox(height: 6),
                      Text('Discover. Connect. Grow.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Explore amazing clubs and amazing people.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: DebouncedSearchBar(
                hint: 'Search clubs...',
                onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
              ),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                children: ['All', ...AppConstants.clubCategories].map((cat) {
                  final selected = category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(_selectedCategoryProvider.notifier).state = cat,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.primaryGradient : null,
                          color: selected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: selected ? Colors.transparent : const Color(0xFFDDE8F5)),
                          boxShadow: selected ? AppShadows.elevated : AppShadows.subtle,
                        ),
                        child: Text(cat, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.textSecondary,
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Club list
          clubs.when(
            data: (list) {
              final filtered = query.isEmpty
                  ? list
                  : list.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No clubs found',
                    subtitle: query.isNotEmpty ? 'Try a different search term.' : 'No clubs in this category yet.',
                    icon: Icons.groups_2_outlined,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClubRowCard(
                        club: filtered[i],
                        onTap: () => context.push('/clubs/${filtered[i].id}'),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: ShimmerBox(width: double.infinity, height: 80),
                  ),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
        ],
        ),
      ),
    );
  }
}

class ClubRowCard extends ConsumerStatefulWidget {
  final ClubModel club;
  final VoidCallback onTap;

  const ClubRowCard({super.key, required this.club, required this.onTap});

  @override
  ConsumerState<ClubRowCard> createState() => _ClubRowCardState();
}

class _ClubRowCardState extends ConsumerState<ClubRowCard> {
  bool _loading = false;

  Future<void> _handleFollowTap(BuildContext context, bool isFollowing, String? uid) async {
    if (uid == null) return;

    if (isFollowing) {
      // Confirm unfollow
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Unfollow Club'),
          content: Text('Unfollow "${widget.club.name}"? You\'ll stop getting their updates.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Following')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unfollow', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _loading = true);
      try {
        await ref.read(clubsServiceProvider).unfollowClub(uid, widget.club.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unfollowed ${widget.club.name}.'), backgroundColor: AppColors.warning),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      setState(() => _loading = true);
      try {
        await ref.read(clubsServiceProvider).followClub(uid, widget.club.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Following ${widget.club.name}!'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isFollowing = currentUser?.followedClubs.contains(club.id) ?? false;
    final isOpen = club.recruitmentStatus == 'open';

    return GestureDetector(
      onTap: widget.onTap,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(club.name, style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (club.isVerified)
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 5, runSpacing: 4,
                    children: [
                      CategoryBadge(label: club.category),
                      ...club.domains.take(2).map((d) => _DomainTag(label: d)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${club.followerCount} followers',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen ? AppColors.successBg : AppColors.errorBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpen ? 'Recruitment Open' : 'Recruitment Closed',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500,
                            color: isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Follow/unfollow button
            GestureDetector(
              onTap: _loading ? null : () => _handleFollowTap(context, isFollowing, currentUser?.uid),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isFollowing ? const Color(0xFFD1FAE5) : AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFollowing ? AppColors.success : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Icon(
                        isFollowing ? Icons.check : Icons.add,
                        color: isFollowing ? AppColors.success : AppColors.primary,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainTag extends StatelessWidget {
  final String label;
  const _DomainTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDDE8F5)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    );
  }
}

// Keep ClubGridCard for backward compat
class ClubGridCard extends StatelessWidget {
  final ClubModel club;
  final VoidCallback onTap;
  const ClubGridCard({super.key, required this.club, required this.onTap});

  @override
  Widget build(BuildContext context) => ClubRowCard(club: club, onTap: onTap);
}