import 'package:flutter/material.dart';
import '../../../services/admin_api_service.dart';

class IslandFormDialog extends StatefulWidget {
  final Map<String, dynamic>? island;

  const IslandFormDialog({super.key, this.island});

  @override
  State<IslandFormDialog> createState() => _IslandFormDialogState();
}

class _IslandFormDialogState extends State<IslandFormDialog> {
  final AdminApiService _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _imgCtrl;
  late TextEditingController _orderCtrl;
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.island?['name'] ?? '');
    _descCtrl = TextEditingController(text: widget.island?['description'] ?? '');
    _imgCtrl = TextEditingController(text: widget.island?['imageUrl'] ?? '');
    _orderCtrl = TextEditingController(text: widget.island?['orderIndex']?.toString() ?? '1');
    _status = widget.island?['status'] ?? 'Active';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'imageUrl': _imgCtrl.text,
        'orderIndex': int.tryParse(_orderCtrl.text) ?? 1,
        'status': _status,
      };

      if (widget.island == null) {
        await _api.createIsland(data);
      } else {
        await _api.updateIsland(widget.island!['islandId'], data);
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
      title: Text(widget.island == null ? 'Thêm Đảo mới' : 'Chỉnh sửa Đảo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên Đảo (*)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên đảo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderCtrl,
                decoration: const InputDecoration(labelText: 'Thứ tự hiển thị', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Hiển thị (Active)')),
                  DropdownMenuItem(value: 'Hidden', child: Text('Ẩn (Hidden)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
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
