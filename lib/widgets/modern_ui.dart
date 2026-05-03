import 'package:flutter/material.dart';

class ModernColors {
  const ModernColors._();

  static const purple = Color(0xFF5B4DF3);
  static const purpleDark = Color(0xFF4C2DD8);
  static const violet = Color(0xFF8B5CF6);
  static const mint = Color(0xFF34D399);
  static const teal = Color(0xFF22C7C7);
  static const amber = Color(0xFFE0A11B);
  static const ink = Color(0xFF080C1F);
  static const muted = Color(0xFF69707D);
  static const page = Color(0xFFF7F8FD);
  static const softPurple = Color(0xFFF0ECFF);
  static const softMint = Color(0xFFEAFBF4);
  static const softCyan = Color(0xFFEAFBFF);
  static const softAmber = Color(0xFFFFF7E8);
  static const darkPage = Color(0xFF0F0B1D);
  static const darkSurface = Color(0xFF1B1730);
  static const darkSurfaceHigh = Color(0xFF241F3C);
}

class AutoHireLogo extends StatelessWidget {
  const AutoHireLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.foreground = Colors.white,
  });

  final double size;
  final bool showWordmark;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ModernColors.purple, Color(0xFF8A35F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: ModernColors.purple.withValues(alpha: 0.32),
            blurRadius: size * 0.26,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.work_rounded, color: foreground, size: size * 0.48),
          Positioned(
            right: size * 0.18,
            top: size * 0.16,
            child: Icon(
              Icons.auto_awesome,
              color: ModernColors.mint,
              size: size * 0.24,
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Text(
          'AutoHire AI',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class ModernPage extends StatelessWidget {
  const ModernPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 88),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: children,
    );
  }
}

class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE8E9F2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ModernIconBox extends StatelessWidget {
  const ModernIconBox({
    super.key,
    required this.icon,
    this.color = ModernColors.purple,
    this.background = ModernColors.softPurple,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class SectionChip extends StatelessWidget {
  const SectionChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: ModernColors.muted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class EmptyActionCard extends StatelessWidget {
  const EmptyActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      child: Column(
        children: [
          ModernIconBox(icon: icon, size: 62),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class PurpleHero extends StatelessWidget {
  const PurpleHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ModernColors.purple, Color(0xFF8A35F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: ModernColors.purple.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
