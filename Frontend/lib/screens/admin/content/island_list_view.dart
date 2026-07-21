import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../../../theme/duo_theme.dart';
import 'island_form_dialog.dart';

class IslandListView extends StatefulWidget {
  const IslandListView({super.key});

  @override
  State<IslandListView> createState() => _IslandListViewState();
}

class _IslandListViewState extends State<IslandListView> {
  final AdminApiService _api = AdminApiService();
  List<dynamic> _islands = [];
  bool _isLoading = true;

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

  Future<void> _deleteIsland(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
          'Bạn có chắc muốn xóa đảo này? Nếu đảo có chứa bài học, bạn sẽ không thể xóa (hãy chuyển trạng thái thành Hidden).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Quản lý Đảo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (_) => const IslandFormDialog(),
                        );
                        if (result == true) _fetchIslands();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm Đảo mới'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Text(
                    'Quản lý Đảo (Nhóm bài học)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => const IslandFormDialog(),
                      );
                      if (result == true) _fetchIslands();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm Đảo mới'),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Thứ tự')),
                            DataColumn(label: Text('Tên Đảo')),
                            DataColumn(label: Text('Mô tả')),
                            DataColumn(label: Text('Số bài học')),
                            DataColumn(label: Text('Trạng thái')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: _islands.map((i) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(i['orderIndex']?.toString() ?? '0'),
                                ),
                                DataCell(Text(i['name'] ?? '')),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      i['description'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(i['situationCount']?.toString() ?? '0'),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: i['status'] == 'Active'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      i['status'] ?? '',
                                      style: TextStyle(
                                        color: i['status'] == 'Active'
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: DuoColors.primaryYellow,
                                        ),
                                        tooltip: 'Sửa',
                                        onPressed: () async {
                                          final result = await showDialog(
                                            context: context,
                                            builder: (_) =>
                                                IslandFormDialog(island: i),
                                          );
                                          if (result == true) _fetchIslands();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Xóa',
                                        onPressed: () =>
                                            _deleteIsland(i['islandId']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
