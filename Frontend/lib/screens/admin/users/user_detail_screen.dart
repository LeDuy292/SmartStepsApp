import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../../../theme/duo_theme.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  const UserDetailScreen({super.key, required this.userId});

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết người dùng')),
        body: const Center(child: Text('Không tìm thấy người dùng')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin cơ bản', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Họ Tên'),
                      subtitle: Text(_user!['fullName'] ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(_user!['email'] ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Vai trò'),
                      subtitle: Text(_user!['role'] ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Trạng thái'),
                      subtitle: Text(
                        _user!['status'] ?? '',
                        style: TextStyle(
                          color: _user!['status'] == 'Active' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thống kê học tập', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox('Bài học đã tham gia', _user!['progressCount'].toString(), Colors.blue),
                        _buildStatBox('Câu hỏi đã trả lời', _user!['answersCount'].toString(), Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
