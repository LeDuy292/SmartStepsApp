import 'package:flutter/material.dart';

import '../theme/duo_theme.dart';
import 'smartsteps_press_effect.dart';

class DuoPrimaryButton extends StatelessWidget {
  const DuoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = DuoColors.primaryYellow,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final bgColor = isEnabled ? backgroundColor : DuoColors.lockedGray;
    final shadowColor = isEnabled
        ? (backgroundColor == DuoColors.primaryYellow
            ? DuoColors.tactileShadow
            : backgroundColor.withAlpha(200))
        : DuoColors.lockedShadow;
    final fgColor = isEnabled ? DuoColors.textPrimary : DuoColors.textSecondary;

    final child = icon == null
        ? Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return SmartStepsPressEffect(
      enabled: isEnabled,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: DefaultTextStyle(
            style: TextStyle(
              color: fgColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily ?? 'Poppins',
            ),
            child: IconTheme(
              data: IconThemeData(color: fgColor),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class DuoCard extends StatelessWidget {
  const DuoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = DuoColors.card,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor ?? DuoColors.lockedGray, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F6B5B00),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DuoProgressBar extends StatelessWidget {
  const DuoProgressBar({
    super.key,
    required this.value,
    this.height = 14,
    this.color = DuoColors.success,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: DuoColors.softYellow,
        color: color,
      ),
    );
  }
}

class DuoAchievementCard extends StatelessWidget {
  const DuoAchievementCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isUnlocked = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUnlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isUnlocked ? DuoColors.primaryYellow : DuoColors.lockedGray;
    final card = DuoCard(
      padding: const EdgeInsets.all(14),
      borderColor: accent.withValues(alpha: 0.55),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Icon(
              isUnlocked ? icon : Icons.lock_rounded,
              color: DuoColors.textPrimary,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null || !isUnlocked) {
      return card;
    }

    return SmartStepsPressEffect(
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}
