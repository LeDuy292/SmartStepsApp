import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../../../theme/duo_theme.dart';
import 'skill_form_dialog.dart';

class SkillListView extends StatefulWidget {
  const SkillListView({super.key});

  @override
  State<SkillListView> createState() => _SkillListViewState();
}

class _SkillListViewState extends State<SkillListView> {
  final AdminApiService _api = AdminApiService();
  List<dynamic> _skills = [];
  bool _isLoading = true;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _deleteSkill(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa kỹ năng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
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
        await _api.deleteSkill(id);
        _fetchSkills();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
                    Text('Quản lý Kỹ năng', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (_) => const SkillFormDialog(),
                        );
                        if (result == true) _fetchSkills();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm Kỹ năng'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Text('Quản lý Kỹ năng (Skills)', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => const SkillFormDialog(),
                      );
                      if (result == true) _fetchSkills();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm Kỹ năng mới'),
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
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Tên Kỹ năng')),
                            DataColumn(label: Text('Mô tả')),
                            DataColumn(label: Text('Số bài học sử dụng')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: _skills.map((s) {
                            return DataRow(
                              cells: [
                                DataCell(Text(s['skillId'].toString())),
                                DataCell(Text(s['name'] ?? '')),
                                DataCell(
                                  SizedBox(
                                    width: 300,
                                    child: Text(
                                      s['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(s['usageCount']?.toString() ?? '0')),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: DuoColors.primaryYellow),
                                      tooltip: 'Sửa',
                                      onPressed: () async {
                                        final result = await showDialog(
                                          context: context,
                                          builder: (_) => SkillFormDialog(skill: s),
                                        );
                                        if (result == true) _fetchSkills();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Xóa',
                                      onPressed: () => _deleteSkill(s['skillId']),
                                    ),
                                  ],
                                )),
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
