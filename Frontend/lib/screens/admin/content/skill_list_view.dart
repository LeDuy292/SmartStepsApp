import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';
import 'skill_form_dialog.dart';

class SkillListView extends StatefulWidget {
  const SkillListView({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<SkillListView> createState() => _SkillListViewState();
}

class _SkillListViewState extends State<SkillListView> {
  final AdminApiService _api = AdminApiService();
  List<dynamic> _skills = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSkills();
  }

  Future<void> _fetchSkills() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getSkills();
      setState(() {
        _skills = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _openForm([Map<String, dynamic>? skill]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SkillFormDialog(skill: skill),
    );
    if (result == true) _fetchSkills();
  }

  Future<void> _deleteSkill(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa kỹ năng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _api.deleteSkill(id);
      _fetchSkills();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  List<dynamic> get _visibleSkills {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _skills;
    return _skills.where((skill) {
      final name = skill['name']?.toString().toLowerCase() ?? '';
      final description = skill['description']?.toString().toLowerCase() ?? '';
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleSkills = _visibleSkills;

    return AdminPageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTopBar(
            title: 'Kỹ năng',
            secondaryAction: adminLogoutAction(widget.onLogout),
          ),
          const SizedBox(height: 12),
          _SkillChartPanel(skills: _skills),
          const SizedBox(height: 12),
          AdminSearchBar(
            hintText: 'Tìm kiếm kỹ năng...',
            onChanged: (value) => setState(() => _searchQuery = value),
            onFilter: () {},
          ),
          const SizedBox(height: 12),
          _FeaturedSkillCard(onAdd: () => _openForm()),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const AdminLoadingState(label: 'Đang tải kỹ năng...')
                : visibleSkills.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Chưa có kỹ năng phù hợp',
                    message: 'Tạo kỹ năng để phân loại nội dung học tập.',
                  )
                : ListView.separated(
                    itemCount: visibleSkills.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final skill = visibleSkills[index];
                      return _SkillCard(
                        skill: skill,
                        color: _skillColor(index),
                        onEdit: () => _openForm(skill),
                        onDelete: () => _deleteSkill(skill['skillId']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _skillColor(int index) {
    const colors = [
      AdminColors.blue,
      AdminColors.teal,
      AdminColors.violet,
      AdminColors.amber,
    ];
    return colors[index % colors.length];
  }
}

class _SkillChartPanel extends StatelessWidget {
  const _SkillChartPanel({required this.skills});

  final List<dynamic> skills;

  @override
  Widget build(BuildContext context) {
    final labels = skills.take(5).map((skill) {
      final name = skill['name']?.toString() ?? 'Kỹ năng';
      return name.length > 7 ? name.substring(0, 7) : name;
    }).toList();
    final safeLabels = labels.isEmpty
        ? ['Nhận biết', 'Vấn đáp', 'Ngôn ngữ', 'Tài chính', 'Xử lý']
        : labels;
    final inUse = List<double>.generate(safeLabels.length, (index) {
      if (index >= skills.length) return 12 + index * 8;
      return math.max(
        8,
        ((skills[index]['usageCount'] as num?)?.toDouble() ?? 0) * 18 + 12,
      );
    });
    final unused = List<double>.generate(safeLabels.length, (index) {
      if (index >= skills.length) return 50 - index * 4;
      final usage = ((skills[index]['usageCount'] as num?)?.toInt() ?? 0);
      return usage == 0 ? 46 : math.max(8, 38 - usage * 6);
    });
    final series = [
      AdminChartSeries(
        values: inUse,
        color: AdminColors.green,
        label: 'Đang dùng',
      ),
      AdminChartSeries(
        values: unused,
        color: AdminColors.orange,
        label: 'Chưa dùng',
      ),
    ];

    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Thống kê kỹ năng',
                  style: TextStyle(
                    color: AdminColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AdminSeriesLegend(items: series),
            ],
          ),
          AdminBarChart(series: series, labels: safeLabels, height: 120),
        ],
      ),
    );
  }
}

class _FeaturedSkillCard extends StatelessWidget {
  const _FeaturedSkillCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.all(12),
      radius: 12,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AdminColors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kỹ năng',
                  style: TextStyle(
                    color: AdminColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Quản lý các năng lực được gắn vào bài học và flashcard.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AdminCircleButton(
            icon: Icons.add_rounded,
            tooltip: 'Thêm kỹ năng',
            onPressed: onAdd,
            color: AdminColors.green,
            backgroundColor: AdminColors.green.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> skill;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final usage = ((skill['usageCount'] as num?)?.toInt() ?? 0);

    return AdminPanel(
      padding: const EdgeInsets.all(12),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.13),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill['name'] ?? 'Chưa đặt tên',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill['description'] ?? 'Chưa có mô tả',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AdminMetricPill(
            icon: usage > 0
                ? Icons.check_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
            label: usage > 0 ? 'Đang dùng' : 'Chưa dùng',
            value: '$usage',
            color: usage > 0 ? AdminColors.blue : AdminColors.muted,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AdminCircleButton(
                icon: Icons.edit_rounded,
                tooltip: 'Sửa kỹ năng',
                onPressed: onEdit,
                color: AdminColors.blue,
                backgroundColor: AdminColors.blue.withValues(alpha: 0.1),
              ),
              const Spacer(),
              AdminCircleButton(
                icon: Icons.delete_rounded,
                tooltip: 'Xóa kỹ năng',
                onPressed: onDelete,
                color: AdminColors.red,
                backgroundColor: AdminColors.red.withValues(alpha: 0.12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
