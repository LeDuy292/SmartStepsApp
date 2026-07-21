import 'package:flutter/material.dart';
import '../../../services/admin_api_service.dart';

class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user; // null if adding
  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final AdminApiService _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _pwdCtrl;
  String _role = 'Child';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?['fullName'] ?? '');
    _emailCtrl = TextEditingController(text: widget.user?['email'] ?? '');
    _pwdCtrl = TextEditingController();
    if (widget.user != null) {
      _role = widget.user!['role'] ?? 'Child';
    }
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
      if (mounted) {
        Navigator.pop(context, true);
      }
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
    return AlertDialog(
      title: Text(
        widget.user == null ? 'Thêm người dùng' : 'Chỉnh sửa người dùng',
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
                decoration: const InputDecoration(labelText: 'Họ và tên'),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    !v!.contains('@') ? 'Email không hợp lệ' : null,
              ),
              if (widget.user == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwdCtrl,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Ít nhất 6 ký tự' : null,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: const [
                  DropdownMenuItem(value: 'Child', child: Text('Trẻ em')),
                  DropdownMenuItem(value: 'Parent', child: Text('Phụ huynh')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
