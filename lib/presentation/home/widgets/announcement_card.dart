import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';

// Announcement Card

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel item;

  const AnnouncementCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isUrgent = item.priority == 'urgent';
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () {},
      color: isUrgent ? const Color(0xFFFFF5F5) : null,
      border: isUrgent
          ? Border.all(color: AppColors.error.withValues(alpha: 0.2))
          : null,
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClubAvatar(imageUrl: item.clubLogoUrl, name: item.clubName ?? 'KIET', size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.clubName ?? 'Campus Wide',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isUrgent) StatusChip.urgent(),
                if (item.isCampusWide && !isUrgent)
                  const StatusChip(label: 'Campus Wide', color: AppColors.info),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

//  Recruitment Card

class RecruitmentCard extends StatelessWidget {
  final RecruitmentModel item;

  const RecruitmentCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () {},
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClubAvatar(imageUrl: item.clubLogoUrl, name: item.clubName, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.clubName,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      StatusChip.open(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.access_time_outlined,
              text: 'Deadline: ${DateFormat('d MMM').format(item.deadline)}',
              iconColor: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

// Event Home Card 

class EventHomeCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventHomeCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          // Date block
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(event.date),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  DateFormat('MMM').format(event.date).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.w500, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(event.clubName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                InfoRow(icon: Icons.location_on_outlined, text: event.venue),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (event.isToday) StatusChip.today()
          else if (event.isUpcoming) StatusChip.upcoming(),
        ],
      ),
    );
  }
}

//Hackathon Card 

class HackathonCard extends StatelessWidget {
  final HackathonModel item;

  const HackathonCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {},
      child: SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: 90,
              decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2),
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
              child: Stack(
                children: [
                  if (item.imageUrl != null)
                    NetworkImageWidget(
                      imageUrl: item.imageUrl,
                      height: 90,
                      width: double.infinity,
                      borderRadius: AppRadius.lg,
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        item.mode.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: '${DateFormat('d MMM').format(item.startDate)} – ${DateFormat('d MMM').format(item.endDate)}',
                  ),
                  if (item.prizePool != null) ...[
                    const SizedBox(height: 4),
                    InfoRow(
                      icon: Icons.emoji_events_outlined,
                      text: 'Prize: ${item.prizePool}',
                      iconColor: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}