import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final bool bordered;
  final bool elevated;
  final Gradient? borderGradient;
  final VoidCallback? onTap;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin,
    this.color,
    this.gradient,
    this.radius = AppRadii.lg,
    this.bordered = true,
    this.elevated = true,
    this.borderGradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = color ?? (isDark ? AppPalette.darkSurface : Colors.white);
    final borderColor = isDark ? AppPalette.darkBorder : AppPalette.border;

    Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: bordered && borderGradient == null
            ? Border.all(color: borderColor)
            : null,
        boxShadow: elevated
            ? (isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : AppShadows.soft)
            : null,
      ),
      child: child,
    );

    if (borderGradient != null) {
      body = Container(
        padding: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
          gradient: borderGradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: elevated
              ? (isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.24),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ]
                    : AppShadows.soft)
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? surface : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius - 1.2),
          ),
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    if (onTap == null) return body;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: body),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconBadge(icon: icon!, color: AppPalette.blue, size: 42),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: isDark ? AppPalette.darkMuted : AppPalette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool filled;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: filled ? null : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        color: filled ? Colors.white : color,
        size: size * 0.52,
      ),
    );
  }
}

class AppPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool outlined;

  const AppPill({
    super.key,
    required this.text,
    this.color = AppPalette.blue,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool expanded;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = const LinearGradient(
      colors: [AppPalette.blue, AppPalette.teal],
    ),
    this.expanded = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: enabled ? AppShadows.glow(AppPalette.teal) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onPressed,
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return AppSurface(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: color, size: 42),
              const Spacer(),
              if (caption != null)
                Flexible(
                  child: Text(
                    caption!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppPalette.darkMuted
                          : AppPalette.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: isDark ? AppPalette.darkMuted : AppPalette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? backgroundColor;
  final Widget? center;
  final Color? trackColor;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 92,
    this.strokeWidth = 9,
    this.color = AppPalette.teal,
    this.backgroundColor,
    this.center,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final track = trackColor ?? backgroundColor ?? Colors.white24;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0, 1)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => CircularProgressIndicator(
                value: animated,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: track,
                color: color,
              ),
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: icon, color: AppPalette.blue, size: 58),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppPalette.darkMuted : AppPalette.muted,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class AppDivider extends StatelessWidget {
  final double vertical;
  const AppDivider({super.key, this.vertical = 18});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Divider(
        height: 1,
        color: isDark ? AppPalette.darkBorder : AppPalette.border,
      ),
    );
  }
}

class AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 60),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
