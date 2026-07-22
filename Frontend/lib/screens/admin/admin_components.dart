import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/duo_theme.dart';

class AdminColors {
  const AdminColors._();

  static const ink = DuoColors.textPrimary;
  static const muted = DuoColors.textSecondary;
  static const surface = DuoColors.card;
  static const page = DuoColors.background;
  static const line = Color(0xFFE8E2C8);
  static const navy = Color(0xFF1E3A5F);
  static const teal = Color(0xFF0F766E);
  static const blue = Color(0xFF0B72D9);
  static const green = Color(0xFF22B573);
  static const amber = Color(0xFFE4A93B);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFE5484D);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFFF6B8A);
  static const cream = Color(0xFFFFFCF4);
}

class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 96),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AdminColors.page,
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

Widget? adminLogoutAction(VoidCallback? onPressed) {
  if (onPressed == null) {
    return null;
  }

  return AdminCircleButton(
    icon: Icons.logout_rounded,
    tooltip: 'Đăng xuất',
    onPressed: onPressed,
    color: AdminColors.red,
    backgroundColor: AdminColors.red.withValues(alpha: 0.1),
  );
}

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    this.primaryAction,
    this.secondaryAction,
    this.avatarText = 'A',
  });

  final String title;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final String avatarText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              color: AdminColors.ink,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
        if (secondaryAction != null) ...[
          const SizedBox(width: 8),
          secondaryAction!,
        ],
        if (primaryAction != null) ...[
          const SizedBox(width: 8),
          primaryAction!,
        ],
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 19,
          backgroundColor: DuoColors.primaryYellow.withValues(alpha: 0.35),
          child: Text(
            avatarText.characters.first.toUpperCase(),
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = 16,
    this.color = AdminColors.surface,
    this.borderColor = AdminColors.line,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x166B5B00),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AdminPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DuoColors.primaryYellow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x336B5B00),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: AdminColors.ink, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    height: 1.08,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AdminColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}

class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onFilter,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AdminColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F6B5B00),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA2AE),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AdminCircleButton(
          icon: Icons.tune_rounded,
          tooltip: 'Lọc',
          onPressed: onFilter,
          color: AdminColors.ink,
          backgroundColor: Colors.white,
        ),
      ],
    );
  }
}

class AdminCircleButton extends StatelessWidget {
  const AdminCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AdminColors.ink,
    this.backgroundColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      color: color,
      style: IconButton.styleFrom(
        minimumSize: const Size(46, 46),
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: backgroundColor ?? color.withValues(alpha: 0.1),
        disabledBackgroundColor: AdminColors.line.withValues(alpha: 0.5),
      ),
    );
  }
}

class AdminActionIcon extends StatelessWidget {
  const AdminActionIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AdminColors.navy,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 19),
      color: color,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: color.withValues(alpha: 0.09),
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});

  final String? status;

  Color get _color {
    switch (status) {
      case 'Active':
      case 'Published':
        return AdminColors.green;
      case 'Locked':
      case 'Hidden':
        return AdminColors.red;
      case 'Draft':
        return AdminColors.amber;
      default:
        return AdminColors.muted;
    }
  }

  String get _label {
    switch (status) {
      case 'Active':
        return 'Hoạt động';
      case 'Inactive':
        return 'Tạm dừng';
      case 'Locked':
        return 'Khóa';
      case 'Hidden':
        return 'Đã ẩn';
      case 'Draft':
        return 'Nháp';
      case 'Published':
        return 'Đã xuất bản';
      default:
        return status?.toString().trim().isNotEmpty == true
            ? status!
            : 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: 0.16)),
      ),
      child: Text(
        _label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AdminRoleChip extends StatelessWidget {
  const AdminRoleChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AdminMiniStatCard extends StatelessWidget {
  const AdminMiniStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AdminColors.amber,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.all(13),
      radius: 10,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMetricPill extends StatelessWidget {
  const AdminMetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AdminColors.navy,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            '$label $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AdminPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: DuoColors.darkYellow),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AdminColors.ink,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key, this.label = 'Đang tải dữ liệu...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: DuoColors.darkYellow),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: AdminColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: DuoColors.darkYellow, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AdminColors.ink,
              fontSize: 18,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class AdminDonutChart extends StatelessWidget {
  const AdminDonutChart({
    super.key,
    required this.segments,
    this.size = 132,
    this.thickness = 28,
  });

  final List<AdminChartSegment> segments;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DonutPainter(segments, thickness)),
    );
  }
}

class AdminBarChart extends StatelessWidget {
  const AdminBarChart({
    super.key,
    required this.series,
    required this.labels,
    this.height = 118,
  });

  final List<AdminChartSeries> series;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BarChartPainter(series, labels),
        child: Padding(
          padding: const EdgeInsets.only(top: 90),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class AdminChartSegment {
  const AdminChartSegment({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;
}

class AdminChartSeries {
  const AdminChartSeries({
    required this.values,
    required this.color,
    required this.label,
  });

  final List<double> values;
  final Color color;
  final String label;
}

class AdminChartLegend extends StatelessWidget {
  const AdminChartLegend({super.key, required this.items});

  final List<AdminChartSegment> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class AdminSeriesLegend extends StatelessWidget {
  const AdminSeriesLegend({super.key, required this.items});

  final List<AdminChartSeries> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.segments, this.thickness);

  final List<AdminChartSegment> segments;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(
      0,
      (sum, item) => sum + math.max(0, item.value),
    );
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;

    stroke.color = const Color(0xFFF1E7CD);
    canvas.drawArc(
      rect.deflate(thickness / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      stroke,
    );

    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final item in segments) {
      final sweep = (item.value / total) * math.pi * 2;
      stroke.color = item.color;
      canvas.drawArc(rect.deflate(thickness / 2), start, sweep, false, stroke);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.thickness != thickness;
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter(this.series, this.labels);

  final List<AdminChartSeries> series;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 28;
    final maxValue = series
        .expand((item) => item.values)
        .fold<double>(1, (max, value) => math.max(max, value));
    final gridPaint = Paint()
      ..color = AdminColors.line.withValues(alpha: 0.75)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = chartHeight - (chartHeight * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (labels.isEmpty || series.isEmpty) return;

    final groupWidth = size.width / labels.length;
    final barWidth = math.min(10.0, (groupWidth - 12) / series.length);
    final totalBarWidth = barWidth * series.length;

    for (var labelIndex = 0; labelIndex < labels.length; labelIndex++) {
      final groupStart =
          groupWidth * labelIndex + (groupWidth - totalBarWidth) / 2;
      for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
        final values = series[seriesIndex].values;
        final rawValue = labelIndex < values.length ? values[labelIndex] : 0;
        final barHeight = (rawValue / maxValue) * (chartHeight - 8);
        final left = groupStart + seriesIndex * barWidth;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            chartHeight - barHeight,
            barWidth * 0.72,
            barHeight,
          ),
          const Radius.circular(3),
        );
        final paint = Paint()..color = series[seriesIndex].color;
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.labels != labels;
  }
}
