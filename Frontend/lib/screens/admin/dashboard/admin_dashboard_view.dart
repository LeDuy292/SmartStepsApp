import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../theme/duo_theme.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.background,
      body: FutureBuilder<AdminDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải dữ liệu dashboard: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshDashboard,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng Quan Hệ Thống',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: DuoColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thống kê hiệu suất và thông tin người dùng SmartSteps',
                          style: TextStyle(
                            fontSize: 14,
                            color: DuoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      onPressed: _refreshDashboard,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Làm mới',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Metrics Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 1100 ? 4 : (width > 550 ? 2 : 1);
                    final childAspectRatio = width > 1100 ? 1.4 : (width > 550 ? 1.6 : 2.4);

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      childAspectRatio: childAspectRatio,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard(
                          title: 'Tổng Người Dùng',
                          value: '${data.users}',
                          icon: Icons.people_alt_rounded,
                          startColor: const Color(0xFF3B82F6),
                          endColor: const Color(0xFF1D4ED8),
                        ),
                        _StatCard(
                          title: 'Bài Học Hoàn Thành',
                          value: '${data.completedLessons}',
                          icon: Icons.task_alt_rounded,
                          startColor: const Color(0xFF10B981),
                          endColor: const Color(0xFF047857),
                        ),
                        _StatCard(
                          title: 'Gói Premium Hoạt Động',
                          value: '${data.activePremium}',
                          icon: Icons.workspace_premium_rounded,
                          startColor: const Color(0xFFF59E0B),
                          endColor: const Color(0xFFB45309),
                        ),
                        _StatCard(
                          title: 'Đánh Giá & Phản Hồi',
                          value: '${data.feedbackCount}',
                          icon: Icons.rate_review_rounded,
                          startColor: const Color(0xFF8B5CF6),
                          endColor: const Color(0xFF6D28D9),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Feedback Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.feedback_outlined,
                              color: DuoColors.primaryYellow,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Góp Ý & Phản Hồi Mới Nhất',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text('${data.feedback.length} mục'),
                              backgroundColor: DuoColors.softYellow,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (data.feedback.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'Chưa có phản hồi nào từ người dùng.',
                                style: TextStyle(color: DuoColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.feedback.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = data.feedback[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: DuoColors.softYellow,
                                  child: Text(
                                    item.email.isNotEmpty
                                        ? item.email[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.email.isNotEmpty
                                            ? item.email
                                            : 'Người dùng ẩn danh',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < item.experienceRating
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 18,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.note.isNotEmpty)
                                        Text(
                                          item.note,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      if (item.submittedAt != null)
                                        Text(
                                          'Thời gian: ${item.submittedAt!.toLocal().toString().split('.').first}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: DuoColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: endColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
