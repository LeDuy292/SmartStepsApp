import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../admin_components.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AdminApiService _api = AdminApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final res = await _api.get('/users/${widget.userId}');
      setState(() {
        _user = res;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: AdminLoadingState(label: 'Đang tải hồ sơ...'),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết người dùng')),
        body: const AdminEmptyState(
          icon: Icons.person_off_rounded,
          title: 'Không tìm thấy người dùng',
          message: 'Tài khoản có thể đã bị xóa hoặc không còn khả dụng.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AdminColors.page,
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        backgroundColor: AdminColors.page,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: AdminPageFrame(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminHeader(
                icon: Icons.person_rounded,
                title: _user!['fullName'] ?? 'Người dùng',
                subtitle: _user!['email'] ?? 'Chưa có email',
                action: AdminStatusChip(status: _user!['status']),
              ),
              const SizedBox(height: 12),
              AdminPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AdminSectionTitle(
                      icon: Icons.badge_outlined,
                      title: 'Thông tin cơ bản',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Họ tên',
                      value: _user!['fullName'] ?? '',
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _user!['email'] ?? '',
                    ),
                    _InfoRow(
                      icon: Icons.security_rounded,
                      label: 'Vai trò',
                      value: _roleLabel(_user!['role']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AdminPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AdminSectionTitle(
                      icon: Icons.insights_rounded,
                      title: 'Thống kê học tập',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        AdminMetricPill(
                          icon: Icons.menu_book_rounded,
                          label: 'Bài học',
                          value: '${_user!['progressCount'] ?? 0}',
                          color: AdminColors.blue,
                        ),
                        AdminMetricPill(
                          icon: Icons.question_answer_rounded,
                          label: 'Câu trả lời',
                          value: '${_user!['answersCount'] ?? 0}',
                          color: AdminColors.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AdminColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
