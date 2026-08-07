import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// ClubSync brand mark — a chain of interlocking rings forming a "C".
/// Pure CustomPainter, no asset required. Drop-in replacement for the
/// old placeholder `Icon(Icons.hub_rounded)`.
class ClubSyncMark extends StatelessWidget {
  final double size;
  final Color color;

  const ClubSyncMark({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ClubSyncMarkPainter(color: color),
    );
  }
}

class _ClubSyncMarkPainter extends CustomPainter {
  final Color color;
  const _ClubSyncMarkPainter({required this.color});

  static const double _startDeg = 55;
  static const double _endDeg = 305;
  static const int _rings = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final orbitR = size.width * 0.30;
    final ringR = size.width * 0.155;
    final ringW = size.width * 0.085;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW
      ..strokeCap = StrokeCap.round
      ..color = color;

    for (int i = 0; i < _rings; i++) {
      final t = _startDeg + (_endDeg - _startDeg) * i / (_rings - 1);
      final rad = t * math.pi / 180;
      final x = cx + orbitR * math.cos(rad);
      final y = cy + orbitR * math.sin(rad);
      canvas.drawCircle(Offset(x, y), ringR, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClubSyncMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

// Neo Button — solid fill, thick black border, hard offset shadow.
// Press animation pushes the button into its own shadow (classic neubrutalist tap).

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final double borderRadius;
  final Widget? icon;
  final bool isLoading;
  final Color? color;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.width,
    this.height = 50,
    this.borderRadius = AppRadius.md,
    this.icon,
    this.isLoading = false,
    this.color,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null || widget.isLoading;
    final fill = disabled ? const Color(0xFFDAD7CE) : (widget.color ?? AppColors.primary);

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(
          _pressed ? 3 : 0, _pressed ? 3 : 0, 0,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: disabled || _pressed ? [] : AppShadows.small,
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// App Card — thick black border, hard offset shadow, no blur.

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? color;
  final List<BoxShadow>? shadows;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = AppRadius.lg,
    this.color,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.cardBg,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows ?? AppShadows.card,
          border: border ?? Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Club Avatar

class ClubAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? color;

  const ClubAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md - 2),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => _buildFallback(),
            errorWidget: (_, __, ___) => _buildFallback(),
          ),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// Status Chip — pill, thick border, dot indicator.

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
  });

  factory StatusChip.open() =>
      const StatusChip(label: 'Open', color: AppColors.success);
  factory StatusChip.closed() =>
      const StatusChip(label: 'Closed', color: AppColors.error);
  factory StatusChip.upcoming() =>
      const StatusChip(label: 'Upcoming', color: AppColors.info);
  factory StatusChip.today() =>
      const StatusChip(label: 'Today', color: AppColors.warning);
  factory StatusChip.urgent() =>
      const StatusChip(label: 'Urgent', color: AppColors.error);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Section Header — chunky rounded display font.

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// Shimmer Loader

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.15), width: 2),
        ),
      ),
    );
  }
}

// Empty State

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              GradientButton(label: actionLabel!, onTap: onAction, width: 170),
            ],
          ],
        ),
      ),
    );
  }
}

// App Search Bar — thick border pill/rounded field.

class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.ink, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          fillColor: Colors.transparent,
          filled: false,
        ),
      ),
    );
  }
}

// Debounced Search Bar

class DebouncedSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;

  const DebouncedSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounceDuration, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      hint: widget.hint,
      controller: _controller,
      onChanged: _onChanged,
    );
  }
}

// Category Badge — solid-tint pill, thin ink border.

class CategoryBadge extends StatelessWidget {
  final String label;

  const CategoryBadge({super.key, required this.label});

  Color get _color {
    switch (label.toLowerCase()) {
      case 'technical':
        return AppColors.technical;
      case 'cultural':
        return AppColors.cultural;
      case 'sports':
        return AppColors.sports;
      case 'finance':
        return AppColors.finance;
      case 'literary':
        return AppColors.literary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _color, width: 1.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// Network Image with Shimmer

class NetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const NetworkImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primaryLighter,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.surfaceVariant,
          highlightColor: Colors.white,
          child: Container(color: Colors.white, width: width, height: height),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// Info Row

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor ?? AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Stat Pill — the flame/trophy/sparkle icon-badge chips seen in the reference UI.

class StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}