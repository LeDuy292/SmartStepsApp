import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/local_profile_storage.dart';
import '../../theme/duo_theme.dart';
import '../login_screen.dart';
import 'admin_components.dart';
import 'content/island_list_view.dart';
import 'content/situation_list_view.dart';
import 'content/skill_list_view.dart';
import 'operations/admin_operations_view.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'users/user_list_view.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const AdminDashboardView(),
    const UserListView(),
    const IslandListView(),
    const SituationListView(),
    const SkillListView(),
    const AdminOperationsView(),
  ];

  Future<void> _handleLogout() async {
    await AuthService().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(
          profileStorage: const LocalProfileStorage(),
          onLogin: (ctx) {
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const AdminLayout(),
              ),
            );
          },
          onRegistrationCompleted: (_) {},
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.background,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: DuoColors.card,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: MediaQuery.of(context).size.width >= 800,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Image.asset(
                'assets/images/logo.png', // Assuming there's a logo or use icon
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: DuoColors.primaryYellow,
                ),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.logout_rounded),
                    color: AdminColors.red,
                    tooltip: 'Đăng xuất',
                    onPressed: _handleLogout,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor: AdminColors.red.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Tổng quan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: Text('Người dùng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: Text('Nhóm bài học'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: Text('Bài học'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.psychology_alt_outlined),
                selectedIcon: Icon(Icons.psychology_alt_rounded),
                label: Text('Kỹ năng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.support_agent_outlined),
                selectedIcon: Icon(Icons.support_agent),
                label: Text('Vận hành'),
              ),
            ],
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: DuoColors.border,
          ),
          Expanded(child: _views[_selectedIndex]),
        ],
      ),
    );
  }
}
