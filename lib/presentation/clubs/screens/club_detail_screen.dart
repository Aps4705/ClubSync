import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/register_button.dart';

final _clubDetailProvider = StreamProvider.family<ClubModel?, String>((ref, id) {
  return ref.watch(clubsServiceProvider).getClub(id);
});

class ClubDetailScreen extends ConsumerWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(_clubDetailProvider(clubId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isFollowing = currentUser?.followedClubs.contains(clubId) ?? false;

    return clubAsync.when(
      data: (club) {
        if (club == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Club')),
            body: const EmptyState(
              title: 'Club not found',
              subtitle: 'This club may have been removed.',
              icon: Icons.groups_2_outlined,
            ),
          );
        }
        return _ClubDetailView(
          club: club,
          isFollowing: isFollowing,
          onFollow: () async {
            if (currentUser == null) return;
            if (isFollowing) {
              await ref.read(clubsServiceProvider).unfollowClub(currentUser.uid, clubId);
            } else {
              await ref.read(clubsServiceProvider).followClub(currentUser.uid, clubId);
            }
          },
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ClubDetailView extends StatefulWidget {
  final ClubModel club;
  final bool isFollowing;
  final VoidCallback onFollow;

  const _ClubDetailView({
    required this.club,
    required this.isFollowing,
    required this.onFollow,
  });

  @override
  State<_ClubDetailView> createState() => _ClubDetailViewState();
}

class _ClubDetailViewState extends State<_ClubDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final isOpen = club.recruitmentStatus == 'open';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // App bar with banner
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner or gradient
                    club.bannerUrl != null && club.bannerUrl!.isNotEmpty
                        ? NetworkImageWidget(imageUrl: club.bannerUrl)
                        : Container(
                            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                          ),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Club logo + name at bottom
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                )
                              ],
                            ),
                            child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: NetworkImageWidget(
                                      imageUrl: club.logoUrl,
                                      width: 68,
                                      height: 68,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      club.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 26,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            club.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            club.category,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Followers row + follow button
SliverToBoxAdapter(
  child: Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
    child: Row(
      children: [
        const Icon(Icons.people_outline, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '${club.followerCount} followers',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        GestureDetector(
          onTap: widget.onFollow,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
            decoration: BoxDecoration(
              gradient: widget.isFollowing ? null : AppColors.primaryGradient,
              color: widget.isFollowing ? AppColors.surfaceVariant : null,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: widget.isFollowing ? Border.all(color: const Color(0xFFDDE8F5)) : null,
              boxShadow: widget.isFollowing ? [] : AppShadows.elevated,
            ),
            child: Text(
              widget.isFollowing ? '✓ Following' : 'Follow',
              style: TextStyle(
                color: widget.isFollowing ? AppColors.textSecondary : Colors.white,
                fontWeight: FontWeight.w600, fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

            // Tab bar 
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Events'),
                    Tab(text: 'Recruitment'),
                    Tab(text: 'Team'),
                  ],
                ),
              ),
            ),
          ],

          body: TabBarView(
            controller: _tabs,
            children: [
              // About
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (club.domains.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _Section(
                        title: 'Domains',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: club.domains
                              .map((d) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLighter,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.full),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      d,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (club.achievements.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _Section(
                        title: 'Achievements',
                        child: Column(
                          children: club.achievements
                              .map((a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.emoji_events_outlined,
                                          size: 16,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            a,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (club.socialLinks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _Section(
                        title: 'Connect With Us',
                        child: Row(
                          children: club.socialLinks
                              .map((link) => Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () =>
                                          launchUrl(Uri.parse(link.url)),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLighter,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.2)),
                                        ),
                                        child: Icon(
                                          _socialIcon(link.platform),
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),

             
// Events
_ClubEventsTab(clubId: club.id),

              //  Recruitment 
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recruitment Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppColors.successBg
                                    : AppColors.errorBg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                isOpen ? 'Open' : 'Closed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: AppShadows.elevated,
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Apply Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.open_in_new,
                                  color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Team 
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _TeamCard(
                      name: club.coreTeam.headName,
                      role: 'Club Head',
                      avatarUrl: club.coreTeam.headAvatarUrl.isNotEmpty
                          ? club.coreTeam.headAvatarUrl
                          : null,
                      isHead: true,
                    ),
                    const SizedBox(height: 10),
                    ...club.coreTeam.members.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TeamCard(
                          name: m.name,
                          role: m.role,
                          avatarUrl: m.avatarUrl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _socialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'linkedin':
        return Icons.work_outline;
      case 'github':
        return Icons.code;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String name;
  final String role;
  final String? avatarUrl;
  final bool isHead;

  const _TeamCard({
    required this.name,
    required this.role,
    this.avatarUrl,
    this.isHead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
        border: isHead
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          ClubAvatar(imageUrl: avatarUrl, name: name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  role,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (isHead)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Text(
                'Head',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class _ClubEventsTab extends ConsumerWidget {
  final String clubId;
  const _ClubEventsTab({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(_clubEventsProvider(clubId));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const EmptyState(
            title: 'No events yet',
            subtitle: 'This club hasn\'t posted any events.',
            icon: Icons.calendar_today_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final event = events[i];
            final month = DateFormat('MMM').format(event.date).toUpperCase();
            final day = DateFormat('d').format(event.date);
            final time = DateFormat('h:mm a').format(event.date);
            final isPast = event.date.isBefore(DateTime.now());

            return Opacity(
              opacity: isPast ? 0.6 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: isPast
                            ? const LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)])
                            : AppColors.primaryGradient,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(month, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          Text(day, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.1)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.access_time_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(event.venue,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: isPast
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Past', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            )
                          : EventRegisterButton(
                              eventId: event.id,
                              eventTitle: event.title,
                              isUpcoming: event.isUpcoming,
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
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 80),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

final _clubEventsProvider = StreamProvider.family<List<EventModel>, String>((ref, clubId) {
  return ref.watch(eventsServiceProvider).getClubEvents(clubId);
});