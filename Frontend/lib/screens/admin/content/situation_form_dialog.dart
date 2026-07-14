import 'package:flutter/material.dart';
import '../../../services/admin_api_service.dart';

class SituationFormDialog extends StatefulWidget {
  final List<dynamic> islands;
  final int? selectedIslandId;
  final Map<String, dynamic>? situation;

  const SituationFormDialog({super.key, required this.islands, this.selectedIslandId, this.situation});

  @override
  State<SituationFormDialog> createState() => _SituationFormDialogState();
}

class _SituationFormDialogState extends State<SituationFormDialog> {
  final AdminApiService _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _introCtrl;
  late TextEditingController _orderCtrl;
  int? _islandId;
  String _status = 'Draft';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.situation?['title'] ?? '');
    _introCtrl = TextEditingController(text: widget.situation?['intro'] ?? '');
    _orderCtrl = TextEditingController(text: widget.situation?['orderIndex']?.toString() ?? '1');
    _status = widget.situation?['status'] ?? 'Draft';
    _islandId = widget.situation?['islandId'] ?? widget.selectedIslandId;
    if (_islandId == null && widget.islands.isNotEmpty) {
      _islandId = widget.islands.first['islandId'];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_islandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn Đảo')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'islandId': _islandId,
        'title': _titleCtrl.text,
        'intro': _introCtrl.text,
        'orderIndex': int.tryParse(_orderCtrl.text) ?? 1,
        'status': _status,
      };

      if (widget.situation == null) {
        await _api.createSituation(data);
      } else {
        await _api.updateSituation(widget.situation!['situationId'], data);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.situation == null ? 'Thêm Bài học mới' : 'Cài đặt Bài học'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _islandId,
                decoration: const InputDecoration(labelText: 'Thuộc Đảo (*)', border: OutlineInputBorder()),
                items: widget.islands.map((i) => DropdownMenuItem<int>(
                  value: i['islandId'],
                  child: Text(i['name']),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _islandId = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Tên Bài học (*)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _introCtrl,
                decoration: const InputDecoration(labelText: 'Giới thiệu ngắn', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _orderCtrl,
                      decoration: const InputDecoration(labelText: 'Thứ tự', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Draft', child: Text('Nháp (Draft)')),
                        DropdownMenuItem(value: 'Published', child: Text('Xuất bản (Published)')),
                        DropdownMenuItem(value: 'Hidden', child: Text('Ẩn (Hidden)')),
                      ],
                      onChanged: widget.situation == null 
                        ? null // New situation is always Draft first
                        : (v) {
                            if (v != null) setState(() => _status = v);
                          },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Lưu'),
        ),
      ],
    );
  }
}
