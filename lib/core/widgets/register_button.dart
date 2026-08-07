import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/services/firebase_services.dart';

class EventRegisterButton extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;
  final bool isUpcoming;
  final bool fullWidth;

  const EventRegisterButton({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.isUpcoming = true,
    this.fullWidth = false,
  });

  @override
  ConsumerState<EventRegisterButton> createState() => _EventRegisterButtonState();
}

class _EventRegisterButtonState extends ConsumerState<EventRegisterButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isRegistered = user?.registeredEvents.contains(widget.eventId) ?? false;

    if (!widget.isUpcoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.4), width: 1.5),
        ),
        child: const Text('Ended', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }

    final child = _loading
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(
            isRegistered ? '✓ Registered' : 'Register',
            style: TextStyle(
              color: isRegistered ? AppColors.success : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );

    return GestureDetector(
      onTap: _loading ? null : () => _handleTap(context, isRegistered, user?.uid),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: widget.fullWidth ? 0 : 12,
          vertical: widget.fullWidth ? 14 : 7,
        ),
        decoration: BoxDecoration(
          gradient: isRegistered ? null : AppColors.primaryGradient,
          color: isRegistered ? AppColors.successBg : null,
          borderRadius: BorderRadius.circular(widget.fullWidth ? 12 : 8),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: isRegistered ? [] : AppShadows.small,
        ),
        child: widget.fullWidth ? Center(child: child) : child,
      ),
    );
  }

Future<void> _handleTap(BuildContext context, bool isRegistered, String? uid) async {
  if (uid == null) return;
  if (!widget.isUpcoming) return; // block registrations for past events


    if (isRegistered) {
      // Confirm unregister
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Registration'),
          content: Text('Cancel your registration for "${widget.eventTitle}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel Registration', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _loading = true);
      try {
        await ref.read(eventsServiceProvider).unregisterFromEvent(uid, widget.eventId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled.'), backgroundColor: AppColors.warning),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // Register
      setState(() => _loading = true);
      try {
        final success = await ref.read(eventsServiceProvider).registerForEvent(uid, widget.eventId);
        if (context.mounted) {
          if (success) {
            _showSuccessDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are already registered!'), backgroundColor: AppColors.info),
            );
          }
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

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle, border: Border.all(color: AppColors.ink, width: 2)),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Registered!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'You\'re registered for "${widget.eventTitle}". Check your profile for details.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.ink, width: 2)),
                child: const Center(child: Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}