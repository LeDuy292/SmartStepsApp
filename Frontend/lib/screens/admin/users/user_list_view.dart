import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../../../theme/duo_theme.dart';
import 'user_form_dialog.dart';

class UserListView extends StatefulWidget {
  const UserListView({super.key});

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  final AdminApiService _api = AdminApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  int _page = 1;
  int _totalPages = 1;
  String _searchQuery = '';
  String _selectedRole = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getUsers(
        page: _page,
        search: _searchQuery,
        role: _selectedRole,
        status: _selectedStatus,
      );
      setState(() {
        _users = res['users'] ?? [];
        _totalPages = res['totalPages'] ?? 1;
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

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa/vô hiệu hóa người dùng này?'),
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
        await _api.deleteUser(id);
        _fetchUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  Future<void> _toggleLockStatus(Map<String, dynamic> user) async {
    final id = user['userId'];
    final isLocked = user['status'] == 'Locked';
    try {
      if (isLocked) {
        await _api.unlockUser(id);
      } else {
        await _api.lockUser(id, 'Admin locked from Dashboard');
      }
      _fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quản lý người dùng',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (_) => const UserFormDialog(),
                            );
                            if (result == true) _fetchUsers();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tìm kiếm',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (val) {
                        _searchQuery = val;
                        _page = 1;
                        _fetchUsers();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedRole.isEmpty ? null : _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Vai trò',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('Tất cả')),
                              DropdownMenuItem(value: 'Child', child: Text('Trẻ em')),
                              DropdownMenuItem(value: 'Parent', child: Text('Phụ huynh')),
                              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _selectedRole = val;
                                _page = 1;
                                _fetchUsers();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStatus.isEmpty ? null : _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Trạng thái',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('Tất cả')),
                              DropdownMenuItem(value: 'Active', child: Text('Hoạt động')),
                              DropdownMenuItem(value: 'Locked', child: Text('Bị khóa')),
                              DropdownMenuItem(value: 'Inactive', child: Text('Ngừng HD')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _selectedStatus = val;
                                _page = 1;
                                _fetchUsers();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Quản lý người dùng',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (_) => const UserFormDialog(),
                          );
                          if (result == true) _fetchUsers();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm người dùng'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Tìm kiếm',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (val) {
                            _searchQuery = val;
                            _page = 1;
                            _fetchUsers();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole.isEmpty ? null : _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Tất cả')),
                            DropdownMenuItem(value: 'Child', child: Text('Trẻ em')),
                            DropdownMenuItem(value: 'Parent', child: Text('Phụ huynh')),
                            DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _selectedRole = val;
                              _page = 1;
                              _fetchUsers();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus.isEmpty ? null : _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Trạng thái',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Tất cả')),
                            DropdownMenuItem(value: 'Active', child: Text('Hoạt động')),
                            DropdownMenuItem(value: 'Locked', child: Text('Bị khóa')),
                            DropdownMenuItem(value: 'Inactive', child: Text('Ngừng HD')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _selectedStatus = val;
                              _page = 1;
                              _fetchUsers();
                            }
                          },
                        ),
                      ),
                    ],
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
                            DataColumn(label: Text('Họ Tên')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Vai trò')),
                            DataColumn(label: Text('Trạng thái')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: _users.map((u) {
                            return DataRow(
                              cells: [
                                DataCell(Text(u['userId'].toString())),
                                DataCell(Text(u['fullName'] ?? '')),
                                DataCell(Text(u['email'] ?? '')),
                                DataCell(Text(u['role'] ?? '')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: u['status'] == 'Active'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : (u['status'] == 'Locked'
                                                ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.grey.withValues(
                                                    alpha: 0.1,
                                                  )),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      u['status'] ?? '',
                                      style: TextStyle(
                                        color: u['status'] == 'Active'
                                            ? Colors.green
                                            : (u['status'] == 'Locked'
                                                  ? Colors.red
                                                  : Colors.grey),
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
                                                UserFormDialog(user: u),
                                          );
                                          if (result == true) _fetchUsers();
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          u['status'] == 'Locked'
                                              ? Icons.lock_open
                                              : Icons.lock,
                                          color: u['status'] == 'Locked'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        tooltip: u['status'] == 'Locked'
                                            ? 'Mở khóa'
                                            : 'Khóa',
                                        onPressed: () => _toggleLockStatus(u),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Xóa',
                                        onPressed: () =>
                                            _deleteUser(u['userId']),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _page > 1
                              ? () {
                                  _page--;
                                  _fetchUsers();
                                }
                              : null,
                        ),
                        Text('Trang $_page / $_totalPages'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _page < _totalPages
                              ? () {
                                  _page++;
                                  _fetchUsers();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
