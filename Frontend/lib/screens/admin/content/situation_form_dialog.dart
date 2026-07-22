import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';

class SituationFormDialog extends StatefulWidget {
  const SituationFormDialog({
    super.key,
    required this.islands,
    this.selectedIslandId,
    this.situation,
  });

  final List<dynamic> islands;
  final int? selectedIslandId;
  final Map<String, dynamic>? situation;

  @override
  State<SituationFormDialog> createState() => _SituationFormDialogState();
}

class _SituationFormDialogState extends State<SituationFormDialog> {
  final AdminApiService _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _introCtrl;
  late final TextEditingController _orderCtrl;
  int? _islandId;
  String _status = 'Draft';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.situation?['title'] ?? '');
    _introCtrl = TextEditingController(text: widget.situation?['intro'] ?? '');
    _orderCtrl = TextEditingController(
      text: widget.situation?['orderIndex']?.toString() ?? '1',
    );
    _status = widget.situation?['status'] ?? 'Draft';
    _islandId = widget.situation?['islandId'] ?? widget.selectedIslandId;
    if (_islandId == null && widget.islands.isNotEmpty) {
      _islandId = widget.islands.first['islandId'];
    }
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _introCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_islandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhóm bài học')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'islandId': _islandId,
        'title': _titleCtrl.text.trim(),
        'intro': _introCtrl.text.trim(),
        'orderIndex': int.tryParse(_orderCtrl.text.trim()) ?? 1,
        'status': _status,
      };

      if (widget.situation == null) {
        await _api.createSituation(data);
      } else {
        await _api.updateSituation(widget.situation!['situationId'], data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.situation != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.tune_rounded : Icons.add_box_rounded,
            color: AdminColors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(isEditing ? 'Cài đặt bài học' : 'Thêm bài học')),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: (MediaQuery.of(context).size.width * 0.9).clamp(280.0, 520.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _islandId,
                  decoration: const InputDecoration(
                    labelText: 'Nhóm bài học',
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.islands
                      .map(
                        (island) => DropdownMenuItem<int>(
                          value: island['islandId'],
                          child: Text(island['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _islandId = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên bài học',
                    prefixIcon: Icon(Icons.title_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên bài học'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _introCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Giới thiệu ngắn',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 420;
                    final order = TextFormField(
                      controller: _orderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự',
                        prefixIcon: Icon(Icons.sort_rounded),
                        border: OutlineInputBorder(),
                      ),
                    );
                    final status = DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Draft',
                          child: Text('Bản nháp'),
                        ),
                        DropdownMenuItem(
                          value: 'Published',
                          child: Text('Xuất bản'),
                        ),
                        DropdownMenuItem(value: 'Hidden', child: Text('Đã ẩn')),
                      ],
                      onChanged: widget.situation == null
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                    );

                    if (isNarrow) {
                      return Column(
                        children: [order, const SizedBox(height: 14), status],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: order),
                        const SizedBox(width: 12),
                        Expanded(child: status),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_isLoading ? 'Đang lưu' : 'Lưu'),
        ),
      ],
    );
  }
}
