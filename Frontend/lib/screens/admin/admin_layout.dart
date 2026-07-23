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
import 'feedback_list_view.dart';
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
      1 => FeedbackListView(onLogout: onLogout),
      2 => UserListView(onLogout: onLogout),
      3 => IslandListView(onLogout: onLogout),
      4 => SituationListView(onLogout: onLogout),
      _ => SkillListView(onLogout: onLogout),
    };
  }


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
                  icon: Icon(Icons.rate_review_outlined),
                  selectedIcon: Icon(Icons.rate_review_rounded),
                  label: 'Phản hồi',
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
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('Tổng quan'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.rate_review_outlined),
                    selectedIcon: Icon(Icons.rate_review_rounded),
                    label: Text('Phản hồi'),
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
