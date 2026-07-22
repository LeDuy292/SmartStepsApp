import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/local_profile_storage.dart';
import '../../theme/duo_theme.dart';
import '../login_screen.dart';
import 'admin_components.dart';
import 'content/island_list_view.dart';
import 'content/situation_list_view.dart';
import 'content/skill_list_view.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'users/user_list_view.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  Widget _buildView({required bool showPageLogout}) {
    final VoidCallback? onLogout = showPageLogout ? _handleLogout : null;

    return switch (_selectedIndex) {
      0 => AdminDashboardView(onLogout: onLogout),
      1 => UserListView(onLogout: onLogout),
      2 => IslandListView(onLogout: onLogout),
      3 => SituationListView(onLogout: onLogout),
      _ => SkillListView(onLogout: onLogout),
    };
  }

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
            body: _buildView(showPageLogout: true),
            bottomNavigationBar: NavigationBar(
              height: 74,
              backgroundColor: DuoColors.card,
              indicatorColor: DuoColors.primaryYellow.withValues(alpha: 0.35),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Tổng quan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Người dùng',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'Nhóm',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Bài học',
                ),
                NavigationDestination(
                  icon: Icon(Icons.psychology_alt_outlined),
                  selectedIcon: Icon(Icons.psychology_alt_rounded),
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
                indicatorColor: DuoColors.primaryYellow.withValues(alpha: 0.35),
                selectedIconTheme: const IconThemeData(color: AdminColors.ink),
                selectedLabelTextStyle: const TextStyle(
                  color: AdminColors.ink,
                  fontWeight: FontWeight.w900,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: AdminColors.muted,
                  fontWeight: FontWeight.w700,
                ),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                extended: constraints.maxWidth >= 900,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Image.asset(
                    'assets/images/logo/logo smartstep-01.webp',
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 48,
                        color: DuoColors.primaryYellow,
                      );
                    },
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
                ],
              ),
              const VerticalDivider(
                thickness: 1,
                width: 1,
                color: AdminColors.line,
              ),
              Expanded(child: _buildView(showPageLogout: false)),
            ],
          ),
        );
      },
    );
  }
}
