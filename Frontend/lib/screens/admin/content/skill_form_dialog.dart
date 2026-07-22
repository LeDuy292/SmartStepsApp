import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';

class SkillFormDialog extends StatefulWidget {
  const SkillFormDialog({super.key, this.skill});

  final Map<String, dynamic>? skill;

  @override
  State<SkillFormDialog> createState() => _SkillFormDialogState();
}

class _SkillFormDialogState extends State<SkillFormDialog> {
  final AdminApiService _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.skill?['name'] ?? '');
    _descCtrl = TextEditingController(text: widget.skill?['description'] ?? '');
  }

  @override
  void dispose() {
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
      };

      if (widget.skill == null) {
        await _api.createSkill(data);
      } else {
        await _api.updateSkill(widget.skill!['skillId'], data);
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
    final isEditing = widget.skill != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
            color: AdminColors.violet,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(isEditing ? 'Chỉnh sửa kỹ năng' : 'Thêm kỹ năng'),
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
                    labelText: 'Tên kỹ năng',
                    prefixIcon: Icon(Icons.psychology_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên kỹ năng'
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
