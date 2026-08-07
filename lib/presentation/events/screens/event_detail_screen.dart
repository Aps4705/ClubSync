import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../core/widgets/register_button.dart';


final _eventDetailProvider = StreamProvider.family<EventModel?, String>((ref, id) {
  return FirebaseFirestore.instance.collection('events').doc(id).snapshots().map(
        (doc) => doc.exists ? EventModel.fromFirestore(doc) : null,
      );
});

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(_eventDetailProvider(eventId));
   
  

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              title: 'Event not found',
              subtitle: 'This event may have been removed.',
              icon: Icons.calendar_today_outlined,
            ),
          );
        }
        return _EventDetailView(
          event: event,
  
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EventDetailView extends StatelessWidget {
  final EventModel event;


  const _EventDetailView({
    required this.event,
 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  event.imageUrl != null
                      ? NetworkImageWidget(imageUrl: event.imageUrl)
                      : Container(
                          decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),gradient: AppColors.primaryGradient),
                          child: const Center(
                            child: Icon(Icons.event_rounded, size: 64, color: Colors.white54),
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + type row
                  Row(
                    children: [
                      if (event.isToday) StatusChip.today()
                      else if (event.isUpcoming) StatusChip.upcoming(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          event.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(event.title, style: Theme.of(context).textTheme.displayMedium),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClubAvatar(imageUrl: event.clubLogoUrl, name: event.clubName, size: 24),
                      const SizedBox(width: 8),
                      Text(event.clubName,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Info cards row
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: DateFormat('EEE, d MMM yyyy').format(event.date),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.access_time_outlined,
                          label: 'Time',
                          value: DateFormat('h:mm a').format(event.date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Venue',
                          value: event.venue,
                          iconColor: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.people_outline,
                          label: 'Registered',
                          value: '${event.registrationCount} students',
                          iconColor: AppColors.success,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text('About this Event', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating register button
bottomNavigationBar: Container(
  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
  decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
    color: Colors.white,
    boxShadow: AppShadows.subtle,
  ),
  child: EventRegisterButton(
    eventId: event.id,
    eventTitle: event.title,
    isUpcoming: event.isUpcoming,
    fullWidth: true,
  ),
),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColors.accent),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}