import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onLogout});
  final Future<void> Function() onLogout;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboardData> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = AdminService().getDashboard();
  }

  Future<void> _refresh() async {
    setState(() => _dashboard = AdminService().getDashboard());
    await _dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị SmartSteps'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FutureBuilder<AdminDashboardData>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Không tải được dashboard: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard('Người dùng', data.users, Icons.people_rounded),
                    _MetricCard(
                      'Bài hoàn thành',
                      data.completedLessons,
                      Icons.school_rounded,
                    ),
                    _MetricCard(
                      'Premium đang dùng',
                      data.activePremium,
                      Icons.workspace_premium_rounded,
                    ),
                    _MetricCard(
                      'Phản hồi',
                      data.feedbackCount,
                      Icons.rate_review_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Phản hồi gần đây',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.feedback.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Chưa có phản hồi.'),
                    ),
                  ),
                ...data.feedback.map(
                  (item) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${item.experienceRating}★'),
                      ),
                      title: Text(item.email),
                      subtitle: Text(
                        item.note.isEmpty ? 'Không có góp ý thêm' : item.note,
                      ),
                      trailing: item.submittedAt == null
                          ? null
                          : Text(
                              '${item.submittedAt!.day}/${item.submittedAt!.month}',
                            ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
