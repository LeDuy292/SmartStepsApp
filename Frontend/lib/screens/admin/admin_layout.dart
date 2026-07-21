import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/local_profile_storage.dart';
import '../login_screen.dart';
import '../../theme/duo_theme.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'users/user_list_view.dart';
import 'content/island_list_view.dart';
import 'content/situation_list_view.dart';
import 'content/skill_list_view.dart';

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
  ];

  final List<String> _titles = [
    'Tổng Quan',
    'Người Dùng',
    'Nhóm Bài Học',
    'Bài Học',
    'Kỹ Năng',
  ];

  Future<void> _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(
            profileStorage: const LocalProfileStorage(),
            onLogin: (ctx) {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminLayout()),
              );
            },
            onRegistrationCompleted: (_) {},
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Scaffold(
            backgroundColor: DuoColors.background,
            appBar: AppBar(
              title: Text(_titles[_selectedIndex]),
              backgroundColor: DuoColors.card,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Đăng xuất',
                  onPressed: _handleLogout,
                ),
              ],
            ),
            body: _views[_selectedIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Tổng quan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Người dùng',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Nhóm',
                ),
                NavigationDestination(
                  icon: Icon(Icons.book_outlined),
                  selectedIcon: Icon(Icons.book),
                  label: 'Bài học',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline),
                  selectedIcon: Icon(Icons.star),
                  label: 'Kỹ năng',
                ),
              ],
            ),
          );
        }

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
                extended: constraints.maxWidth >= 900,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Image.asset(
                    'assets/images/logo/logo smartstep-01.webp',
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.admin_panel_settings,
                          size: 48, color: DuoColors.primaryYellow);
                    },
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        tooltip: 'Đăng xuất',
                        onPressed: _handleLogout,
                      ),
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Tổng quan'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Người dùng'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: Text('Nhóm bài học'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.book_outlined),
                    selectedIcon: Icon(Icons.book),
                    label: Text('Bài học'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.star_outline),
                    selectedIcon: Icon(Icons.star),
                    label: Text('Kỹ năng'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1, color: DuoColors.border),
              Expanded(
                child: _views[_selectedIndex],
              ),
            ],
          ),
        );
      },
    );
  }
}
