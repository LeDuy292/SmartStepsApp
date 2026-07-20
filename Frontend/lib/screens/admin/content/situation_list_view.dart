import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../../../theme/duo_theme.dart';
import 'situation_form_dialog.dart';
import 'situation_editor_screen.dart';

class SituationListView extends StatefulWidget {
  const SituationListView({super.key});

  @override
  State<SituationListView> createState() => _SituationListViewState();
}

class _SituationListViewState extends State<SituationListView> {
  final AdminApiService _api = AdminApiService();
  List<dynamic> _situations = [];
  List<dynamic> _islands = [];
  int? _selectedIslandId;
  bool _isLoading = true;

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

  Future<void> _deleteSituation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
          'Bạn có chắc muốn xóa bài học này? Nếu đã có dữ liệu người dùng, bài học sẽ chỉ bị ẩn (Hidden).',
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Quản lý Bài học (Situations)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 32),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedIslandId,
                  decoration: const InputDecoration(
                    labelText: 'Lọc theo Đảo',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả các đảo'),
                    ),
                    ..._islands.map(
                      (i) => DropdownMenuItem<int?>(
                        value: i['islandId'],
                        child: Text(i['name']),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    _selectedIslandId = v;
                    _fetchData();
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => SituationFormDialog(
                      islands: _islands,
                      selectedIslandId: _selectedIslandId,
                    ),
                  );
                  if (result == true) _fetchData();
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm Bài học mới'),
              ),
            ],
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
                            DataColumn(label: Text('Đảo')),
                            DataColumn(label: Text('Tên bài học')),
                            DataColumn(label: Text('Steps')),
                            DataColumn(label: Text('Flashcards')),
                            DataColumn(label: Text('Trạng thái')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: _situations.map((s) {
                            return DataRow(
                              cells: [
                                DataCell(Text(s['situationId'].toString())),
                                DataCell(Text(s['islandName'] ?? '')),
                                DataCell(
                                  SizedBox(
                                    width: 250,
                                    child: Text(
                                      s['title'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(s['stepCount']?.toString() ?? '0'),
                                ),
                                DataCell(
                                  Text(s['flashcardCount']?.toString() ?? '0'),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: s['status'] == 'Published'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : (s['status'] == 'Hidden'
                                                ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.orange.withValues(
                                                    alpha: 0.1,
                                                  )),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s['status'] ?? '',
                                      style: TextStyle(
                                        color: s['status'] == 'Published'
                                            ? Colors.green
                                            : (s['status'] == 'Hidden'
                                                  ? Colors.red
                                                  : Colors.orange),
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
                                          Icons.edit_document,
                                          color: DuoColors.primaryYellow,
                                        ),
                                        tooltip:
                                            'Sửa nội dung (Steps, Flashcards)',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SituationEditorScreen(
                                                    situationId:
                                                        s['situationId'],
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.settings,
                                          color: Colors.blue,
                                        ),
                                        tooltip:
                                            'Cài đặt bài học (Tên, Trạng thái)',
                                        onPressed: () async {
                                          final result = await showDialog(
                                            context: context,
                                            builder: (_) => SituationFormDialog(
                                              islands: _islands,
                                              situation: s,
                                            ),
                                          );
                                          if (result == true) _fetchData();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Xóa',
                                        onPressed: () =>
                                            _deleteSituation(s['situationId']),
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
