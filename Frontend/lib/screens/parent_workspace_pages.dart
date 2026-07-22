import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../theme/duo_theme.dart';
import 'family_screen.dart';

class ParentChildrenPage extends StatelessWidget {
  const ParentChildrenPage({super.key});

  @override
  Widget build(BuildContext context) => const FamilyScreen();
}

class ParentProgressPage extends StatefulWidget {
  const ParentProgressPage({super.key});

  @override
  State<ParentProgressPage> createState() => _ParentProgressPageState();
}

class _ParentProgressPageState extends State<ParentProgressPage> {
  final _service = FamilyService();
  late Future<List<Map<String, dynamic>>> _children;

  @override
  void initState() {
    super.initState();
    _children = _service.getChildren();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DuoColors.background,
    appBar: AppBar(title: const Text('Tiến độ của trẻ')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _children,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        final children = snapshot.data ?? const [];
        if (children.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Hãy liên kết hoặc tạo tài khoản trẻ trước khi xem tiến độ.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _ProgressCard(child: children[index], service: _service),
        );
      },
    ),
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.child, required this.service});

  final Map<String, dynamic> child;
  final FamilyService service;

  @override
  Widget build(BuildContext context) {
    final childId = child['userId'] as int;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFF0E8D8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Map<String, dynamic>>(
        future: service.getReport(childId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: LinearProgressIndicator(),
            );
          }
          final data = snapshot.data!;
          final week = Map<String, dynamic>.from(data['week'] as Map);
          final daily = (data['daily'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          final skills = (data['skills'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          final history = (data['history'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          final aiAssessment = data['aiAssessment'] is Map
              ? Map<String, dynamic>.from(data['aiAssessment'] as Map)
              : null;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: DuoColors.softYellow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
                        color: DuoColors.darkYellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        child['fullName']?.toString() ?? 'Trẻ',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _WeeklyOverview(week: week),
                const SizedBox(height: 22),
                _AiAssessmentCard(data: aiAssessment),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Nhịp học trong tuần',
                  subtitle: 'Số câu trẻ đã trả lời mỗi ngày',
                  child: _WeeklyChart(items: daily),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Phân tích kỹ năng',
                  subtitle: 'Điểm mạnh và nội dung cần quan tâm',
                  child: _SkillList(items: skills),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Lịch sử học tập',
                  subtitle: 'Các bài học được truy cập gần đây',
                  child: _HistoryList(items: history),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeeklyOverview extends StatelessWidget {
  const _WeeklyOverview({required this.week});
  final Map<String, dynamic> week;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBF0),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFF3E6C9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: DuoColors.primaryYellow.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: DuoColors.darkYellow,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan 7 ngày',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    'Hoạt động gần nhất của trẻ',
                    style: TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final items = [
              _Metric(
                label: 'Ngày có học',
                value: '${week['activeDays'] ?? 0}/7',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF8B5CF6),
              ),
              _Metric(
                label: 'Bài hoàn thành',
                value: '${week['completedLessons'] ?? 0}',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF22C55E),
              ),
              _Metric(
                label: 'Câu trả lời',
                value: '${week['totalAnswers'] ?? 0}',
                icon: Icons.quiz_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ];
            final accuracy = _AccuracyCard(
              value: week['accuracy'] as num? ?? 0,
            );
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  accuracy,
                  const SizedBox(height: 10),
                  for (final item in items) ...[
                    item,
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: accuracy),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        items[index],
                        if (index < items.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _AccuracyCard extends StatelessWidget {
  const _AccuracyCard({required this.value});
  final num value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD84D), Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.track_changes_rounded, size: 30),
        const SizedBox(height: 12),
        Text(
          '$value%',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Tỷ lệ chính xác',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (value / 100).clamp(0, 1).toDouble(),
          minHeight: 7,
          color: DuoColors.textPrimary,
          backgroundColor: Colors.white54,
          borderRadius: BorderRadius.circular(99),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF8),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF1E9DA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: DuoColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _AiAssessmentCard extends StatelessWidget {
  const _AiAssessmentCard({required this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF5F3FF), Color(0xFFEFF6FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDD6FE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED)),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'AI đánh giá sự tiến bộ',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ),
            _AiBadge(),
          ],
        ),
        const SizedBox(height: 12),
        if (data == null)
          const Text(
            'Chưa có báo cáo AI. Hệ thống sẽ đánh giá khi trẻ có đủ dữ liệu học tập.',
            style: TextStyle(color: DuoColors.textSecondary, height: 1.4),
          )
        else ...[
          Text(
            data!['summary']?.toString() ?? 'Đã có đánh giá mới cho trẻ.',
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: 12),
          _AiInsight(
            icon: Icons.thumb_up_alt_rounded,
            title: 'Điểm mạnh',
            text: data!['strengths']?.toString() ?? 'Chưa có dữ liệu.',
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 8),
          _AiInsight(
            icon: Icons.lightbulb_rounded,
            title: 'Cần quan tâm',
            text:
                data!['areasForImprovement']?.toString() ?? 'Chưa có dữ liệu.',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ],
    ),
  );
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF7C3AED),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'AI',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _AiInsight extends StatelessWidget {
  const _AiInsight({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: color),
      const SizedBox(width: 9),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: DuoColors.textPrimary, height: 1.35),
            children: [
              TextSpan(
                text: '$title: ',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: text),
            ],
          ),
        ),
      ),
    ],
  );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<num>(
      1,
      (max, item) =>
          (item['answers'] as num? ?? 0) > max ? item['answers'] as num : max,
    );
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return SizedBox(
      height: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${items[index]['answers'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height:
                          86 *
                          ((items[index]['answers'] as num? ?? 0) / maxValue),
                      constraints: const BoxConstraints(minHeight: 5),
                      decoration: BoxDecoration(
                        color: DuoColors.primaryYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      index < labels.length ? labels[index] : '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: DuoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkillList extends StatelessWidget {
  const _SkillList({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('Chưa đủ dữ liệu để phân tích kỹ năng.');
    }
    return Column(
      children: [
        for (final item in items.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name']?.toString() ?? 'Kỹ năng',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('${item['accuracy'] ?? 0}%'),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: ((item['accuracy'] as num? ?? 0) / 100)
                      .clamp(0, 1)
                      .toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                  color: (item['accuracy'] as num? ?? 0) >= 70
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF59E0B),
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('Trẻ chưa bắt đầu bài học nào.');
    return Column(
      children: [
        for (final item in items.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              item['status'] == 'Completed'
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_fill_rounded,
              color: item['status'] == 'Completed'
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B),
            ),
            title: Text(
              item['title']?.toString() ?? 'Bài học',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              item['status'] == 'Completed' ? 'Đã hoàn thành' : 'Đang học',
            ),
            trailing: Text(
              '${item['accuracy'] ?? 0}%',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}

class ParentAccountPage extends StatelessWidget {
  const ParentAccountPage({
    super.key,
    required this.onManagePremium,
    required this.onLogout,
  });

  final VoidCallback onManagePremium;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DuoColors.background,
    appBar: AppBar(title: const Text('Tài khoản phụ huynh')),
    body: FutureBuilder<String?>(
      future: AuthService().getUserEmail(),
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.family_restroom_rounded, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phụ huynh',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(snapshot.data ?? 'Đang tải...'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onManagePremium,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Thanh toán và quản lý Premium'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ],
      ),
    ),
  );
}
