import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';

class IslandFormDialog extends StatefulWidget {
  const IslandFormDialog({super.key, this.island});

  final Map<String, dynamic>? island;

  @override
  State<IslandFormDialog> createState() => _IslandFormDialogState();
}

class _IslandFormDialogState extends State<IslandFormDialog> {
  final AdminApiService _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imgCtrl;
  late final TextEditingController _orderCtrl;
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.island?['name'] ?? '');
    _descCtrl = TextEditingController(
      text: widget.island?['description'] ?? '',
    );
    _imgCtrl = TextEditingController(text: widget.island?['imageUrl'] ?? '');
    _orderCtrl = TextEditingController(
      text: widget.island?['orderIndex']?.toString() ?? '1',
    );
    _status = widget.island?['status'] ?? 'Active';
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _imgCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrl': _imgCtrl.text.trim(),
        'orderIndex': int.tryParse(_orderCtrl.text.trim()) ?? 1,
        'status': _status,
      };

      if (widget.island == null) {
        await _api.createIsland(data);
      } else {
        await _api.updateIsland(widget.island!['islandId'], data);
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
    final isEditing = widget.island != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            isEditing
                ? Icons.edit_location_alt_rounded
                : Icons.add_location_alt_rounded,
            color: AdminColors.teal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(isEditing ? 'Chỉnh sửa nhóm' : 'Thêm nhóm bài học'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: (MediaQuery.of(context).size.width * 0.9).clamp(280.0, 480.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    prefixIcon: Icon(Icons.terrain_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên nhóm'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imgCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ảnh đại diện',
                    hintText: 'URL hình ảnh nếu có',
                    prefixIcon: Icon(Icons.image_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _orderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thứ tự',
                          prefixIcon: Icon(Icons.sort_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Active',
                            child: Text('Hoạt động'),
                          ),
                          DropdownMenuItem(
                            value: 'Hidden',
                            child: Text('Đã ẩn'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                    ),
                  ],
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
