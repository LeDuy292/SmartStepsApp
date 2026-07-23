import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';
import 'situation_editor_screen.dart';
import 'situation_form_dialog.dart';

class SituationListView extends StatefulWidget {
  const SituationListView({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<SituationListView> createState() => _SituationListViewState();
}

class _SituationListViewState extends State<SituationListView> {
  final AdminApiService _api = AdminApiService();
  List<dynamic> _situations = [];
  List<dynamic> _islands = [];
  int? _selectedIslandId;
  String _selectedStatus = '';
  String _searchQuery = '';
  bool _isLoading = true;
  int _page = 1;
  static const int _pageSize = 3;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final islands = await _api.getIslands();
      final situations = await _api.getSituations(islandId: _selectedIslandId);

      setState(() {
        _islands = islands;
        _situations = situations;
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

  Future<void> _openForm([Map<String, dynamic>? situation]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SituationFormDialog(
        islands: _islands,
        selectedIslandId: _selectedIslandId,
        situation: situation,
      ),
    );
    if (result == true) _fetchData();
  }

  Future<void> _deleteSituation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Nếu bài học đã có dữ liệu người dùng, hệ thống sẽ chỉ ẩn bài học thay vì xóa vĩnh viễn.',
        ),
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
      await _api.deleteSituation(id);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _openEditor(Map<String, dynamic> situation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SituationEditorScreen(situationId: situation['situationId']),
      ),
    );
  }

  List<dynamic> get _visibleSituations {
    final query = _searchQuery.trim().toLowerCase();
    return _situations.where((situation) {
      final title = situation['title']?.toString().toLowerCase() ?? '';
      final island = situation['islandName']?.toString().toLowerCase() ?? '';
      final matchesSearch =
          query.isEmpty || title.contains(query) || island.contains(query);
      final matchesStatus =
          _selectedStatus.isEmpty || situation['status'] == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalPages {
    final count = _visibleSituations.length;
    return count == 0 ? 1 : ((count - 1) ~/ _pageSize) + 1;
  }

  List<dynamic> get _pagedSituations {
    final safePage = _page > _totalPages ? _totalPages : _page;
    final start = (safePage - 1) * _pageSize;
    final situations = _visibleSituations;
    if (start >= situations.length) {
      return const [];
    }
    final end = (start + _pageSize) > situations.length
        ? situations.length
        : start + _pageSize;
    return situations.sublist(start, end);
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Lọc bài học',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedIslandId,
                  decoration: const InputDecoration(
                    labelText: 'Nhóm bài học',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả nhóm'),
                    ),
                    ..._islands.map(
                      (island) => DropdownMenuItem<int?>(
                        value: island['islandId'],
                        child: Text(island['name']),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedIslandId = value;
                    _page = 1;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tất cả')),
                    DropdownMenuItem(
                      value: 'Published',
                      child: Text('Đã xuất bản'),
                    ),
                    DropdownMenuItem(value: 'Draft', child: Text('Nháp')),
                    DropdownMenuItem(value: 'Hidden', child: Text('Ẩn')),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedStatus = value ?? '';
                    _page = 1;
                  }),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchData();
                  },
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: const Text('Áp dụng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSituations = _visibleSituations;
    final pagedSituations = _pagedSituations;

    return AdminPageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTopBar(
            title: 'Bài học',
            primaryAction: AdminCircleButton(
              icon: Icons.add_rounded,
              tooltip: 'Thêm bài học',
              onPressed: () => _openForm(),
              color: AdminColors.green,
              backgroundColor: AdminColors.green.withValues(alpha: 0.16),
            ),
            secondaryAction: adminLogoutAction(widget.onLogout),
          ),
          const SizedBox(height: 10),
          _LessonChartPanel(situations: _situations),
          const SizedBox(height: 12),
          AdminSearchBar(
            hintText: 'Tìm kiếm bài học...',
            onChanged: (value) => setState(() {
              _searchQuery = value;
              _page = 1;
            }),
            onFilter: _showFilters,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const AdminLoadingState(label: 'Đang tải bài học...')
                : visibleSituations.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.library_books_outlined,
                    title: 'Chưa có bài học phù hợp',
                    message: 'Tạo bài học mới hoặc đổi bộ lọc.',
                  )
                : ListView.separated(
                    itemCount: pagedSituations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final situation = pagedSituations[index];
                      return _LessonCard(
                        situation: situation,
                        index: index,
                        onEditContent: () => _openEditor(situation),
                        onSettings: () => _openForm(situation),
                        onDelete: () =>
                            _deleteSituation(situation['situationId']),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          AdminPagination(
            page: _page,
            totalPages: _totalPages,
            onPrevious: _page > 1 ? () => setState(() => _page--) : null,
            onNext: _page < _totalPages ? () => setState(() => _page++) : null,
          ),
        ],
      ),
    );
  }
}

class _LessonChartPanel extends StatelessWidget {
  const _LessonChartPanel({required this.situations});

  final List<dynamic> situations;

  @override
  Widget build(BuildContext context) {
    final labels = situations.take(6).map((situation) {
      final text = situation['title']?.toString() ?? 'Bài';
      return text.length > 6 ? text.substring(0, 6) : text;
    }).toList();
    final safeLabels = labels.isEmpty
        ? ['Tháng', 'Tháng', 'Tháng', 'Tháng', 'Tháng']
        : labels;
    final published = _valuesFor('Published', safeLabels.length);
    final draft = _valuesFor('Draft', safeLabels.length);
    final hidden = _valuesFor('Hidden', safeLabels.length);
    final series = [
      AdminChartSeries(
        values: published,
        color: AdminColors.green,
        label: 'Đã xuất bản',
      ),
      AdminChartSeries(
        values: draft,
        color: const Color(0xFFFFCC3D),
        label: 'Nháp',
      ),
      AdminChartSeries(
        values: hidden,
        color: AdminColors.violet,
        label: 'Thêm',
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
                  'Thống kê bài học',
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
          AdminBarChart(series: series, labels: safeLabels, height: 128),
        ],
      ),
    );
  }

  List<double> _valuesFor(String status, int count) {
    final base = situations
        .where((situation) => situation['status'] == status)
        .length
        .toDouble();
    return List<double>.generate(count, (index) {
      final wobble = (index + 1) * 9.0;
      return math.max(8, base * 16 + wobble);
    });
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.situation,
    required this.index,
    required this.onEditContent,
    required this.onSettings,
    required this.onDelete,
  });

  final Map<String, dynamic> situation;
  final int index;
  final VoidCallback onEditContent;
  final VoidCallback onSettings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AdminColors.blue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chrome_reader_mode_rounded,
                  color: AdminColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bài ${index + 1}: ${situation['title'] ?? 'Chưa đặt tên'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                    ),
                    Text(
                      situation['islandName'] ?? 'Chưa gắn nhóm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusChip(status: situation['status']),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminMetricPill(
                icon: Icons.format_list_bulleted_rounded,
                label: 'Steps',
                value: '${situation['stepCount'] ?? 0}',
                color: AdminColors.teal,
              ),
              AdminMetricPill(
                icon: Icons.quiz_rounded,
                label: 'Flashcards',
                value: '${situation['flashcardCount'] ?? 0}',
                color: AdminColors.violet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AdminCircleButton(
                icon: Icons.play_arrow_rounded,
                tooltip: 'Soạn nội dung',
                onPressed: onEditContent,
                color: AdminColors.teal,
                backgroundColor: AdminColors.teal.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 8),
              AdminCircleButton(
                icon: Icons.tune_rounded,
                tooltip: 'Cài đặt',
                onPressed: onSettings,
                color: AdminColors.blue,
                backgroundColor: AdminColors.blue.withValues(alpha: 0.1),
              ),
              const Spacer(),
              AdminCircleButton(
                icon: Icons.delete_rounded,
                tooltip: 'Xóa',
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
