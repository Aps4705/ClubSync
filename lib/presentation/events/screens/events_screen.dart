import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';
import '../../../core/widgets/register_button.dart';

final _eventFilterProvider = StateProvider<String>((ref) => 'all');
final _eventSearchProvider = StateProvider<String>((ref) => '');
final _filteredEventsProvider = StreamProvider.family<List<EventModel>, String>((ref, filter) {
  return ref.watch(eventsServiceProvider).getEvents(filter: filter == 'all' ? null : filter);
});

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_eventFilterProvider);
    final search = ref.watch(_eventSearchProvider);
    final events = ref.watch(_filteredEventsProvider(filter));
    final showSearch = ref.watch(_showSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(_filteredEventsProvider(filter));
        },
        child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Events', style: Theme.of(context).textTheme.displayMedium),
                        Row(children: [
                          _IconBtn(
                            icon: Icons.search,
                            onTap: () => ref.read(_showSearchProvider.notifier).state = !showSearch,
                          ),
                        ]),
                      ],
                    ),
                    if (showSearch) ...[
                      const SizedBox(height: 12),
                      DebouncedSearchBar(
                        hint: 'Search events...',
                        onChanged: (v) => ref.read(_eventSearchProvider.notifier).state = v,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          
// Filter tabs
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          _Tab(label: 'All', value: 'all', current: filter, ref: ref),
          _Tab(label: 'This Week', value: 'week', current: filter, ref: ref),
          _Tab(label: 'Today', value: 'today', current: filter, ref: ref),
          _Tab(label: 'Done', value: 'completed', current: filter, ref: ref),
        ],
      ),
    ),
  ),
),

          events.when(
           data: (list) {
  
  List<EventModel> filtered = list;
  if (filter == 'all') {
    filtered = list.where((e) => e.date.isAfter(DateTime.now())).toList();
  }
  if (search.isNotEmpty) {
    filtered = filtered.where((e) =>
        e.title.toLowerCase().contains(search.toLowerCase()) ||
        e.clubName.toLowerCase().contains(search.toLowerCase())).toList();
  }

              if (filtered.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No events found',
                    subtitle: 'Check back later for upcoming events.',
                    icon: Icons.calendar_today_outlined,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EventListCard(
                        event: filtered[i],
                        onTap: () => context.push('/events/${filtered[i].id}'),
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
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerBox(width: double.infinity, height: 100),
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

final _showSearchProvider = StateProvider<bool>((ref) => false);

class _Tab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;

  const _Tab({required this.label, required this.value, required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(_eventFilterProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
            gradient: selected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMuted,
            )),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.subtle,
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class EventListCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventListCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMM').format(event.date).toUpperCase();
    final day = DateFormat('d').format(event.date);
    final time = DateFormat('h:mm a').format(event.date);
    final dayOfWeek = DateFormat('EEE').format(event.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(month, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(day, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.1)),
                Text(dayOfWeek, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(event.clubName, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.access_time_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.venue,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
              ),
            ),
Padding(
  padding: const EdgeInsets.only(right: 14),
  child: EventRegisterButton(
    eventId: event.id,
    eventTitle: event.title,
    isUpcoming: event.isUpcoming,
  ),
),
          ],
        ),
      ),
    );
  }
}