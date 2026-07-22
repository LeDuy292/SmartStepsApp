import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.user});

  final Map<String, dynamic>? user;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final AdminApiService _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _pwdCtrl;
  String _role = 'Child';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?['fullName'] ?? '');
    _emailCtrl = TextEditingController(text: widget.user?['email'] ?? '');
    _pwdCtrl = TextEditingController();
    _role = widget.user?['role'] ?? 'Child';
  }

  @override
  void dispose() {
    _pwdCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'fullName': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _role,
    };

    try {
      if (widget.user == null) {
        data['password'] = _pwdCtrl.text;
        await _api.createUser(data);
      } else {
        await _api.updateUser(widget.user!['userId'], data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            isEditing
                ? Icons.manage_accounts_rounded
                : Icons.person_add_alt_1_rounded,
            color: AdminColors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(isEditing ? 'Chỉnh sửa người dùng' : 'Thêm người dùng'),
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
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập họ và tên'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: isEditing
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Email không hợp lệ'
                      : null,
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pwdCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Mật khẩu cần ít nhất 6 ký tự'
                        : null,
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Child', child: Text('Trẻ em')),
                    DropdownMenuItem(value: 'Parent', child: Text('Phụ huynh')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_isSaving ? 'Đang lưu' : 'Lưu'),
        ),
      ],
    );
  }
}
