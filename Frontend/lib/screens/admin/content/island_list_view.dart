import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';
import 'island_form_dialog.dart';

class IslandListView extends StatefulWidget {
  const IslandListView({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<IslandListView> createState() => _IslandListViewState();
}

class _IslandListViewState extends State<IslandListView> {
  final AdminApiService _api = AdminApiService();
  List<dynamic> _islands = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchIslands();
  }

  Future<void> _fetchIslands() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getIslands();
      setState(() {
        _islands = res;
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

  Future<void> _openForm([Map<String, dynamic>? island]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => IslandFormDialog(island: island),
    );
    if (result == true) _fetchIslands();
  }

  Future<void> _deleteIsland(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Nếu nhóm bài học đã có bài học bên trong, hệ thống có thể từ chối xóa. Khi đó hãy chuyển trạng thái sang Đã ẩn.',
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
      await _api.deleteIsland(id);
      _fetchIslands();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  List<dynamic> get _visibleIslands {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _islands;
    return _islands.where((island) {
      final name = island['name']?.toString().toLowerCase() ?? '';
      final description = island['description']?.toString().toLowerCase() ?? '';
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleIslands = _visibleIslands;
    final totalLessons = _islands.fold<int>(
      0,
      (sum, island) => sum + ((island['situationCount'] as num?)?.toInt() ?? 0),
    );

    return AdminPageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTopBar(
            title: 'Nhóm bài học',
            secondaryAction: AdminCircleButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Thông báo',
              onPressed: null,
              backgroundColor: Colors.white,
            ),
            primaryAction: adminLogoutAction(widget.onLogout),
          ),
          const SizedBox(height: 14),
          AdminSearchBar(
            hintText: 'Tìm kiếm nhóm bài học...',
            onChanged: (value) => setState(() => _searchQuery = value),
            onFilter: () {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AdminMiniStatCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Tổng nhóm:',
                  value: '${_islands.length}',
                  color: AdminColors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminMiniStatCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Tổng bài học:',
                  value: '$totalLessons',
                  color: AdminColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _isLoading
                ? const AdminLoadingState(label: 'Đang tải nhóm bài học...')
                : visibleIslands.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.travel_explore_rounded,
                    title: 'Chưa có nhóm bài học phù hợp',
                    message: 'Tạo nhóm đầu tiên để tổ chức hành trình học.',
                  )
                : ListView.separated(
                    itemCount: visibleIslands.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final island = visibleIslands[index];
                      return _IslandCard(
                        island: island,
                        color: _cardColor(index),
                        icon: _cardIcon(index),
                        onEdit: () => _openForm(island),
                        onDelete: () => _deleteIsland(island['islandId']),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _openForm(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFFE9B861),
              foregroundColor: AdminColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Thêm nhóm mới'),
          ),
        ],
      ),
    );
  }

  Color _cardColor(int index) {
    const colors = [
      AdminColors.green,
      AdminColors.violet,
      AdminColors.pink,
      AdminColors.blue,
    ];
    return colors[index % colors.length];
  }

  IconData _cardIcon(int index) {
    const icons = [
      Icons.shield_rounded,
      Icons.school_rounded,
      Icons.favorite_rounded,
      Icons.explore_rounded,
    ];
    return icons[index % icons.length];
  }
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({
    required this.island,
    required this.color,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> island;
  final Color color;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.all(13),
      radius: 12,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.26),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 31),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            island['name'] ?? 'Chưa đặt tên',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        AdminStatusChip(status: island['status']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      island['description'] ?? 'Level 1 - An toàn cá nhân',
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AdminMetricPill(
                icon: Icons.sort_rounded,
                label: 'Thứ tự:',
                value: '${island['orderIndex'] ?? 0}',
                color: AdminColors.muted,
              ),
              const SizedBox(width: 8),
              AdminMetricPill(
                icon: Icons.menu_book_rounded,
                label: 'Bài học:',
                value: '${island['situationCount'] ?? 0}',
                color: AdminColors.muted,
              ),
              const Spacer(),
              _SmallIcon(icon: Icons.edit_rounded, onTap: onEdit),
              _SmallIcon(icon: Icons.delete_outline_rounded, onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 19),
      color: const Color(0xFF9CA3AF),
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
