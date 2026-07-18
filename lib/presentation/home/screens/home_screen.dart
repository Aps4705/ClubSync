import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/services/firebase_services.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/register_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final announcements = ref.watch(_announcementsProvider(currentUser?.followedClubs ?? []));
    final recruitments = ref.watch(_recruitmentsProvider);
    final events = ref.watch(_eventsProvider);
    final searchQuery = ref.watch(_homeSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(_announcementsProvider(currentUser?.followedClubs ?? []));
          ref.invalidate(_recruitmentsProvider);
          ref.invalidate(_eventsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HeroHeader(user: currentUser)),

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: DebouncedSearchBar(
                  hint: 'Search clubs, events...',
                  onChanged: (v) => ref.read(_homeSearchProvider.notifier).state = v,
                ),
              ),
            ),

            // Search results
            if (searchQuery.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text('Search results for "$searchQuery"',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
              ),
              SliverToBoxAdapter(
                child: _SearchResults(query: searchQuery),
              ),
            ] else ...[
              // Happening now
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: SectionHeader(title: 'Happening now', actionLabel: 'See all'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 176,
                  child: events.when(
                    data: (list) {
                      final upcoming = list.where((e) => e.isUpcoming).toList();
                      return upcoming.isEmpty
                        ? recruitments.when(
                            data: (rList) => rList.isEmpty
                                ? const Center(child: Text('No events yet', style: TextStyle(color: AppColors.textMuted)))
                                : _AutoSlider(items: rList.take(3).map((r) =>
                                    _SlideItem(
                                      gradient: AppColors.featuredCard1,
                                      tag: 'Recruitment',
                                      clubName: r.clubName,
                                      title: r.title,
                                      sub: 'Closes ${_fmt(r.deadline)}',
                                      isLive: true,
                                      onTap: null, // recruitments don't have a detail screen yet
                                    )
                                  ).toList()),
                            loading: () => const _HorizontalShimmer(count: 2, height: 176, width: 260),
                            error: (_, __) => const SizedBox(),
                          )
                        : _AutoSlider(
                            items: upcoming.take(4).toList().asMap().entries.map((e) {
                              final gradients = [AppColors.featuredCard1, AppColors.featuredCard2, AppColors.featuredCard3];
                              return _SlideItem(
                                gradient: gradients[e.key % gradients.length],
                                tag: e.value.type,
                                clubName: e.value.clubName,
                                title: e.value.title,
                                sub: '${_fmt(e.value.date)} · ${e.value.venue}',
                                isLive: e.value.isToday,
                                onTap: () => context.push('/events/${e.value.id}'),
                              );
                            }).toList(),
                          );
                    },
                    loading: () => const _HorizontalShimmer(count: 2, height: 176, width: 260),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ),

              // Browse clubs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: SectionHeader(
                    title: 'Browse clubs',
                    actionLabel: 'See all',
                    onAction: () => context.go('/clubs'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _ClubCategoryRow(onTap: (_) => context.go('/clubs')),
              ),

              // Upcoming events
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: SectionHeader(
                    title: 'Upcoming Events',
                    actionLabel: 'See all',
                    onAction: () => context.go('/events'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: events.when(
                  data: (list) {
                    final upcoming = list.where((e) => e.isUpcoming).toList();
                    return upcoming.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _EmptySection(text: 'No upcoming events.'),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: upcoming.take(4)
                                .map((e) => _EventTimelineCard(
                                      event: e,
                                      onTap: () => context.push('/events/${e.id}'),
                                    ))
                                .toList(),
                          ),
                        );
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(3, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerBox(width: double.infinity, height: 72),
                      )),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),

              // Announcements
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: SectionHeader(title: 'Announcements', actionLabel: 'See all'),
                ),
              ),
              SliverToBoxAdapter(
                child: announcements.when(
                  data: (list) => list.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _EmptySection(text: 'No announcements right now.'),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: list.take(3).map((a) => _AnnouncementTile(item: a)).toList(),
                          ),
                        ),
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(2, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerBox(width: double.infinity, height: 80),
                      )),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime? d) {
  if (d == null) return '';
  return '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]}';
}

//Auto Slider

class _SlideItem {
  final LinearGradient gradient;
  final String tag;
  final String clubName;
  final String title;
  final String sub;
  final bool isLive;
  final VoidCallback? onTap;
  const _SlideItem({
    required this.gradient, required this.tag,
    required this.clubName,
    required this.title, required this.sub,
    this.isLive = false, this.onTap,
  });
}

class _AutoSlider extends StatefulWidget {
  final List<_SlideItem> items;
  const _AutoSlider({required this.items});

  @override
  State<_AutoSlider> createState() => _AutoSliderState();
}

class _AutoSliderState extends State<_AutoSlider> {
  final _controller = PageController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      Future.delayed(const Duration(seconds: 5), _autoScroll);
    }
  }

  void _autoScroll() {
    if (!mounted) return;
    final next = (_current + 1) % widget.items.length;
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    setState(() => _current = next);
    Future.delayed(const Duration(seconds: 5), _autoScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(gradient: item.gradient, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (item.isLive) ...[
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          const Text('LIVE', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text(item.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(item.clubName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.title, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(item.sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: item.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(item.isLive ? 'Register Now' : 'View Details',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Dots indicator
        if (widget.items.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.items.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _current == i ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ],
      ],
    );
  }
}

//Hero Header

class _HeroHeader extends StatelessWidget {
  final UserModel? user;
  const _HeroHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final name = user?.name.split(' ').first ?? 'Student';

    return Container(
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                 const Text(
  'ClubSync',
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    letterSpacing: 0.3,
    shadows: [
      Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
      Shadow(color: Colors.white24, blurRadius: 16, offset: Offset(0, 0)),
    ],
  ),
),
                ],
              ),
              const SizedBox(height: 18),
              Text('$greeting,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const SizedBox(height: 2),
              Text('$name 👋', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24)),
              const SizedBox(height: 4),
              Text('Stay updated. Never miss an opportunity.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatChip(icon: Icons.groups_2_outlined, value: '${user?.followedClubs.length ?? 0}', label: 'Following'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.calendar_today_outlined, value: '${user?.registeredEvents.length ?? 0}', label: 'Events'),
                  const SizedBox(width: 10),
                  const _StatChip(icon: Icons.emoji_events_outlined, value: '0', label: 'Hackathons'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// Search Results

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(_clubsSearchProvider);
    final events = ref.watch(_eventsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          clubs.when(
            data: (list) {
              final filtered = list.where((c) =>
                  c.name.toLowerCase().contains(query.toLowerCase()) ||
                  c.category.toLowerCase().contains(query.toLowerCase())).toList();
              if (filtered.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clubs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...filtered.take(3).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => context.push('/clubs/${c.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
                        child: Row(children: [
                          ClubAvatar(imageUrl: c.logoUrl, name: c.name, size: 40),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(c.category, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ])),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                        ]),
                      ),
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          events.when(
            data: (list) {
              final filtered = list.where((e) =>
                  e.title.toLowerCase().contains(query.toLowerCase()) ||
                  e.clubName.toLowerCase().contains(query.toLowerCase())).toList();
              if (filtered.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Events', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...filtered.take(3).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => context.push('/events/${e.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text(DateFormat('d').format(e.date), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(e.clubName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ])),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                        ]),
                      ),
                    ),
                  )),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

// Category Row

class _ClubCategoryRow extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _ClubCategoryRow({required this.onTap});

  static const _cats = [
    ('Technical', Icons.computer_outlined, AppColors.technical),
    ('Cultural', Icons.theater_comedy_outlined, AppColors.cultural),
    ('Sports', Icons.sports_soccer_outlined, AppColors.sports),
    ('Finance', Icons.bar_chart_outlined, AppColors.finance),
    ('Literary', Icons.menu_book_outlined, AppColors.literary),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _cats.map((c) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => onTap(c.$1),
            child: Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: c.$3.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.$3.withValues(alpha: 0.2)),
                ),
                child: Icon(c.$2, color: c.$3, size: 24),
              ),
              const SizedBox(height: 6),
              Text(c.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}

//Event Timeline Card

class _EventTimelineCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  const _EventTimelineCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMM').format(event.date).toUpperCase();
    final day = DateFormat('d').format(event.date);
    final time = DateFormat('h:mm a').format(event.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.card),
        child: Row(
          children: [
            Container(
              width: 48, height: 52,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(month, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                Text(day, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${event.clubName} · $time', style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 8),
           EventRegisterButton(
  eventId: event.id,
  eventTitle: event.title,
  isUpcoming: event.isUpcoming,
),
          ],
        ),
      ),
    );
  }
}

// Announcement Tile 

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementModel item;
  const _AnnouncementTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(item.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(item.clubName ?? 'Campus-wide', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _HorizontalShimmer extends StatelessWidget {
  final int count;
  final double height;
  final double width;
  const _HorizontalShimmer({required this.count, required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => ShimmerBox(width: width, height: height),
      ),
    );
  }
}

//Providers 

final _homeSearchProvider = StateProvider<String>((ref) => '');
final _clubsSearchProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(clubsServiceProvider).getClubs();
});
final _announcementsProvider = StreamProvider.family<List<AnnouncementModel>, List<String>>((ref, clubs) {
  return ref.watch(announcementsServiceProvider).getAnnouncements(followedClubs: clubs);
});
final _recruitmentsProvider = StreamProvider<List<RecruitmentModel>>((ref) {
  return ref.watch(recruitmentsServiceProvider).getOpenRecruitments();
});
final _eventsProvider = StreamProvider<List<EventModel>>((ref) {
  return ref.watch(eventsServiceProvider).getEvents();
});
final _hackathonsProvider = StreamProvider<List<HackathonModel>>((ref) {
  return ref.watch(hackathonsServiceProvider).getHackathons();
});