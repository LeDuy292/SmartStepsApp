import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../../theme/duo_theme.dart';
import '../admin_components.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final AdminService _adminService = AdminService();
  late Future<AdminDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = _adminService.getDashboard();
    });
  }

  Future<void> _refresh() async {
    _refreshDashboard();
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AdminPageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminTopBar(
                  title: 'Tổng quan',
                  primaryAction: adminLogoutAction(widget.onLogout),
                ),
                const SizedBox(height: 14),
                const Expanded(
                  child: AdminLoadingState(label: 'Đang tải tổng quan...'),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return AdminPageFrame(
            child: AdminEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Không tải được dashboard',
              message: 'Kiểm tra kết nối hoặc thử làm mới lại dữ liệu.',
            ),
          );
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          color: DuoColors.darkYellow,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: AdminPageFrame(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminTopBar(
                    title: 'Tổng quan',
                    primaryAction: adminLogoutAction(widget.onLogout),
                  ),
                  const SizedBox(height: 14),
                  _CommandCenterCard(onRefresh: _refreshDashboard),
                  const SizedBox(height: 16),
                  _MetricsGrid(data: data),
                  const SizedBox(height: 14),
                  _GrowthPanel(data: data),
                  const SizedBox(height: 14),
                  _FeedbackPanel(data: data),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommandCenterCard extends StatelessWidget {
  const _CommandCenterCard({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      color: const Color(0xFFFFF8DD),
      borderColor: const Color(0xFFF3DA72),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Trung tâm điều hành',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Theo dõi người dùng, tiến độ học và phản hồi mới nhất của SmartSteps.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: AdminColors.ink,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 4 : 2;
        final ratio = width >= 900 ? 1.08 : 1.12;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          childAspectRatio: ratio,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              title: 'Người dùng',
              value: '${data.users}',
              helper: 'Tài khoản trong hệ thống',
              icon: Icons.people_alt_rounded,
              color: AdminColors.blue,
            ),
            _MetricCard(
              title: 'Hoàn thành',
              value: '${data.completedLessons}',
              helper: 'Bài học đã hoàn tất',
              icon: Icons.check_circle_rounded,
              color: AdminColors.green,
            ),
            _MetricCard(
              title: 'Premium',
              value: '${data.activePremium}',
              helper: 'Gói đang hoạt động',
              icon: Icons.workspace_premium_rounded,
              color: AdminColors.amber,
            ),
            _MetricCard(
              title: 'Phản hồi',
              value: '${data.feedbackCount}',
              helper: 'Đánh giá từ người dùng',
              icon: Icons.chat_bubble_rounded,
              color: AdminColors.violet,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progressValue(value),
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  double _progressValue(String raw) {
    final value = int.tryParse(raw) ?? 0;
    if (value <= 0) return 0.06;
    return math.min(1, math.max(0.18, value / 12));
  }
}

class _GrowthPanel extends StatelessWidget {
  const _GrowthPanel({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final values = <double>[
      0.05,
      math.max(0.08, data.users / 20),
      math.max(0.18, data.completedLessons / 14),
      math.max(0.12, data.activePremium / 8),
      math.max(0.28, data.feedbackCount / 10),
      math.max(0.36, (data.users + data.completedLessons) / 24),
      math.max(0.64, (data.users + data.feedbackCount + 2) / 18),
    ].map((value) => value.clamp(0.04, 1.0)).toList();

    return _DashboardPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê tăng trưởng',
            style: TextStyle(
              color: AdminColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 104,
            child: CustomPaint(
              painter: _GrowthChartPainter(values),
              child: const Padding(
                padding: EdgeInsets.only(top: 74),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('T2', style: _axisStyle),
                    Text('T3', style: _axisStyle),
                    Text('T4', style: _axisStyle),
                    Text('T5', style: _axisStyle),
                    Text('T6', style: _axisStyle),
                    Text('T7', style: _axisStyle),
                    Text('CN', style: _axisStyle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Phản hồi mới nhất',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8DD),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFF3DA72)),
                ),
                child: Text(
                  '${data.feedback.length} mục',
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (data.feedback.isEmpty)
            const Text(
              'Chưa có phản hồi mới.',
              style: TextStyle(
                color: AdminColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(3, data.feedback.length),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _FeedbackTile(item: data.feedback[index]),
            ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final email = item.email.isNotEmpty ? item.email : 'Người dùng ẩn danh';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: DuoColors.primaryYellow,
            child: Text(
              email.characters.first.toUpperCase(),
              style: const TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < item.experienceRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 15,
                          color: AdminColors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.ink,
                      height: 1.3,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = Colors.white,
    this.borderColor = AdminColors.line,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x146B5B00),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GrowthChartPainter extends CustomPainter {
  const _GrowthChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 28;
    final chartWidth = size.width;
    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = index * chartWidth / (values.length - 1);
      final y = chartHeight - (values[index] * (chartHeight - 12)) + 2;
      points.add(Offset(x, y));
    }

    final baseline = chartHeight + 1;
    final areaPath = Path()..moveTo(points.first.dx, baseline);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      areaPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    areaPath
      ..lineTo(points.last.dx, baseline)
      ..close();

    final gridPaint = Paint()
      ..color = AdminColors.line.withValues(alpha: 0.75)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      gridPaint,
    );

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x995DADE2), Color(0x19FACC15)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF2E86C1)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

const _axisStyle = TextStyle(
  color: AdminColors.muted,
  fontSize: 11,
  fontWeight: FontWeight.w800,
);
