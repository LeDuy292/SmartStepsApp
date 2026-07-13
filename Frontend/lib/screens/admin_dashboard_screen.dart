import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Logged out')))),
                  (route) => false,
                );
                // In a real app we'd route back to SmartStepsApp or LoginScreen with proper parameters
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Chào mừng Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Các tính năng quản lý sẽ được thêm tại đây.'),
          ],
        ),
      ),
    );
  }
}
