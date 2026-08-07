import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/services/firebase_services.dart';

final _registeredEventsProvider = StreamProvider<List<EventModel>>((ref) async* {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.registeredEvents.isEmpty) {
    yield [];
    return;
  }
 
  yield* ref.watch(eventsServiceProvider).getEventsByIds(user.registeredEvents);
});

class RegisteredEventsScreen extends ConsumerWidget {
  const RegisteredEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final eventsAsync = ref.watch(_registeredEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registered Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : user.registeredEvents.isEmpty
              ? const EmptyState(
                  title: 'No events registered',
                  subtitle: 'Events you register for will appear here.',
                  icon: Icons.calendar_today_outlined,
                )
              : eventsAsync.when(
                  data: (fetchedEvents) {
                   
                    final registered = [...fetchedEvents]
                      ..sort((a, b) => a.date.compareTo(b.date));

                    if (registered.isEmpty) {
                      return const EmptyState(
                        title: 'No events registered',
                        subtitle: 'Events you register for will appear here.',
                        icon: Icons.calendar_today_outlined,
                      );
                    }

                    final upcoming = registered.where((e) => e.date.isAfter(DateTime.now())).toList();
                    final past = registered.where((e) => !e.date.isAfter(DateTime.now())).toList();

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (upcoming.isNotEmpty) ...[
                          const Text('Upcoming', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          ...upcoming.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EventCard(event: e, onTap: () => context.push('/events/${e.id}')),
                          )),
                        ],
                        if (past.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Past', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          ...past.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EventCard(event: e, onTap: () => context.push('/events/${e.id}'), isPast: true),
                          )),
                        ],
                      ],
                    );
                  },
                  loading: () => ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 90),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isPast;

  const _EventCard({required this.event, required this.onTap, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMM').format(event.date).toUpperCase();
    final day = DateFormat('d').format(event.date);
    final time = DateFormat('h:mm a').format(event.date);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isPast ? 0.6 : 1.0,
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
                  gradient: isPast
                      ? const LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)])
                      : AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(month, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(day, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.1)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(event.title, style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(event.clubName, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.access_time_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.venue,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: isPast
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Attended', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Registered ✓', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}