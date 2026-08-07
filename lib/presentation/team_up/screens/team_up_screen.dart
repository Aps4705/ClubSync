import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';
import 'package:url_launcher/url_launcher.dart';

final _teamUpPostsProvider = StreamProvider<List<TeamUpPost>>((ref) {
  return ref.watch(teamUpServiceProvider).getPosts();
});

final _skillFilterProvider = StateProvider<String?>((ref) => null);

class TeamUpScreen extends ConsumerWidget {
  const TeamUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(_teamUpPostsProvider);
    final skillFilter = ref.watch(_skillFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(_teamUpPostsProvider);
          },
          child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Team Up', style: Theme.of(context).textTheme.displayMedium),
                        Text('Find teammates for hackathons & projects',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/team-up/create'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: AppShadows.elevated,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Post',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Skill filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _SkillChip(
                        label: 'All',
                        isSelected: skillFilter == null,
                        onTap: () => ref.read(_skillFilterProvider.notifier).state = null,
                      ),
                      ...AppConstants.skillTags.map((s) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _SkillChip(
                              label: s,
                              isSelected: skillFilter == s,
                              onTap: () => ref.read(_skillFilterProvider.notifier).state =
                                  skillFilter == s ? null : s,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // Posts list
            postsAsync.when(
              data: (posts) {
                final filtered = skillFilter == null
                    ? posts
                    : posts
                        .where((p) => p.skillsNeeded
                            .any((s) => s.toLowerCase().contains(skillFilter.toLowerCase())))
                        .toList();

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      title: skillFilter != null ? 'No posts for "$skillFilter"' : 'No posts yet',
                      subtitle: 'Be the first to post a team request!',
                      icon: Icons.diversity_3_outlined,
                      actionLabel: 'Post Now',
                      onAction: () => context.push('/team-up/create'),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TeamUpPostCard(post: filtered[i]),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(width: double.infinity, height: 160),
                    ),
                    childCount: 4,
                  ),
                ),
              ),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SkillChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: isSelected ? null : Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Changed to ConsumerWidget so we can read currentUser
class TeamUpPostCard extends ConsumerWidget {
  final TeamUpPost post;
  const TeamUpPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwner = currentUser?.uid == post.authorUid;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              ClubAvatar(imageUrl: post.authorAvatarUrl, name: post.authorName, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${post.authorBranch} · ${post.authorYear}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Show "Your Post" badge if owner
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text(
                    'Your Post',
                    style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Text(
                  timeago.format(post.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Text(post.title, style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 6),
          Text(
            post.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Skills needed
          if (post.skillsNeeded.isNotEmpty) ...[
            const Text('Skills needed',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.skillsNeeded
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Bottom row — hackathon tag + buttons
          Row(
            children: [
              if (post.linkedHackathon != null) ...[
                const Icon(Icons.emoji_events_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    post.linkedHackathon!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),

              // Edit + Close buttons — only for post owner
              if (isOwner) ...[
                GestureDetector(
                  onTap: () => context.push('/team-up/edit', extra: post),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg)),
                        title: const Text('Close Request'),
                        content: const Text(
                            'Found your team? Mark this request as closed — it will be removed from the list.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Close Request',
                                style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(teamUpServiceProvider).closePost(post.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request closed successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Close Request',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else ...[
                // Connect button — only for non-owners
                GestureDetector(
                  onTap: () async {
                    final contact = post.contactInfo.trim();
                    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
                    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');

                    Uri? uri;
                    if (contact.startsWith('http://') || contact.startsWith('https://')) {
                      uri = Uri.tryParse(contact);
                    } else if (emailRegex.hasMatch(contact)) {
                      uri = Uri.tryParse('mailto:$contact');
                    } else if (phoneRegex.hasMatch(contact)) {
                      uri = Uri.tryParse('tel:$contact');
                    }

                    if (uri == null || !(await canLaunchUrl(uri))) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Couldn't open contact info — it may be invalid."),
                          ),
                        );
                      }
                      return;
                    }
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: const Text(
                      'Connect',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}