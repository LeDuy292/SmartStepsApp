import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';
import 'user_form_dialog.dart';

class UserListView extends StatefulWidget {
  const UserListView({super.key, this.onLogout});

  final VoidCallback? onLogout;

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

  Future<void> _openUserForm([Map<String, dynamic>? user]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );
    if (result == true) _fetchUsers();
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa hoặc vô hiệu hóa người dùng này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
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

  List<dynamic> get _visibleUsers {
    final query = _searchQuery.trim().toLowerCase();
    return _users.where((user) {
      final name = user['fullName']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final matchesSearch =
          query.isEmpty || name.contains(query) || email.contains(query);
      return matchesSearch;
    }).toList();
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'Child':
        return 'Trẻ em';
      case 'Parent':
        return 'Phụ huynh';
      case 'Admin':
        return 'Admin';
      default:
        return role ?? 'Không rõ';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'Child':
        return AdminColors.green;
      case 'Parent':
        return AdminColors.amber;
      case 'Admin':
        return AdminColors.blue;
      default:
        return AdminColors.muted;
    }
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Lọc người dùng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Parent', child: Text('Phụ huynh')),
                    DropdownMenuItem(value: 'Child', child: Text('Trẻ em')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedRole = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'Active', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'Locked', child: Text('Khóa')),
                    DropdownMenuItem(
                      value: 'Inactive',
                      child: Text('Tạm dừng'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedStatus = value ?? ''),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    _page = 1;
                    Navigator.pop(context);
                    _fetchUsers();
                  },
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: const Text('Áp dụng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _visibleUsers;

    return AdminPageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTopBar(
            title: 'Người dùng',
            secondaryAction: AdminCircleButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Thông báo',
              onPressed: () {},
              backgroundColor: Colors.white,
            ),
            primaryAction: adminLogoutAction(widget.onLogout),
          ),
          const SizedBox(height: 14),
          _UserStatsPanel(users: _users, roleLabel: _roleLabel),
          const SizedBox(height: 12),
          AdminSearchBar(
            hintText: 'Tìm kiếm người dùng...',
            onChanged: (value) => setState(() => _searchQuery = value),
            onFilter: _showFilters,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _openUserForm(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Thêm người dùng'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: AdminColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const AdminLoadingState(label: 'Đang tải người dùng...')
                : visibleUsers.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'Không có người dùng phù hợp',
                    message: 'Thử đổi từ khóa hoặc bộ lọc.',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720 ? 3 : 2;
                      return GridView.builder(
                        itemCount: visibleUsers.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: constraints.maxWidth >= 720
                              ? 1.18
                              : 0.96,
                        ),
                        itemBuilder: (context, index) {
                          final user = visibleUsers[index];
                          return _UserCard(
                            user: user,
                            roleLabel: _roleLabel(user['role']),
                            roleColor: _roleColor(user['role']),
                            onEdit: () => _openUserForm(user),
                            onLock: () => _toggleLockStatus(user),
                            onDelete: () => _deleteUser(user['userId']),
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          AdminPagination(
            showWhenSinglePage: true,
            page: _page,
            totalPages: _totalPages,
            onPrevious: _page > 1
                ? () {
                    _page--;
                    _fetchUsers();
                  }
                : null,
            onNext: _page < _totalPages
                ? () {
                    _page++;
                    _fetchUsers();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _UserStatsPanel extends StatelessWidget {
  const _UserStatsPanel({required this.users, required this.roleLabel});

  final List<dynamic> users;
  final String Function(String?) roleLabel;

  @override
  Widget build(BuildContext context) {
    final adminCount = users.where((user) => user['role'] == 'Admin').length;
    final parentCount = users.where((user) => user['role'] == 'Parent').length;
    final childCount = users.where((user) => user['role'] == 'Child').length;
    final total = users.isEmpty ? 1 : users.length;
    final segments = [
      AdminChartSegment(
        value: adminCount.toDouble(),
        color: AdminColors.blue,
        label: 'Admin',
      ),
      AdminChartSegment(
        value: parentCount.toDouble(),
        color: const Color(0xFFFFCC3D),
        label: 'Phụ huynh',
      ),
      AdminChartSegment(
        value: childCount.toDouble(),
        color: AdminColors.green,
        label: 'Trẻ em',
      ),
    ];

    return AdminPanel(
      padding: const EdgeInsets.all(14),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Thống kê người dùng',
            style: TextStyle(
              color: AdminColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AdminDonutChart(segments: segments, size: 132),
                Text(
                  '$total',
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AdminChartLegend(items: segments),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.roleLabel,
    required this.roleColor,
    required this.onEdit,
    required this.onLock,
    required this.onDelete,
  });

  final Map<String, dynamic> user;
  final String roleLabel;
  final Color roleColor;
  final VoidCallback onEdit;
  final VoidCallback onLock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = user['fullName']?.toString().trim().isNotEmpty == true
        ? user['fullName'].toString()
        : 'Chưa có tên';
    final email = user['email']?.toString() ?? '';

    return AdminPanel(
      padding: const EdgeInsets.all(9),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  adminInitial(name),
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusChip(status: user['status']),
            ],
          ),
          const SizedBox(height: 10),
          AdminRoleChip(label: roleLabel, color: roleColor),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MiniAction(icon: Icons.edit_rounded, onTap: onEdit),
              _MiniAction(
                icon: user['status'] == 'Locked'
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                onTap: onLock,
              ),
              _MiniAction(icon: Icons.delete_outline_rounded, onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      color: const Color(0xFF6B7280),
      tooltip: 'Thao tác',
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
