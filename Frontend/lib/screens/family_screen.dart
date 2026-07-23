
import 'package:flutter/material.dart';

import '../services/family_service.dart';
import '../theme/duo_theme.dart';
import '../widgets/child_selection_dialog.dart';
import 'parent_task_reward_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _service = FamilyService();
  late Future<List<Map<String, dynamic>>> _children;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _children = _service.getChildren();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DuoColors.background,
    appBar: AppBar(
      title: const Text('Trẻ em'),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await ChildSelectionDialog.show(context);
          },
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Đổi / Chọn bé'),
        ),
        IconButton(
          tooltip: 'Tạo hồ sơ trẻ',
          onPressed: _createChild,
          icon: const Icon(Icons.person_add_rounded),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _children,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final children = snapshot.data ?? const [];
        if (children.isEmpty) {
          return _EmptyFamily(onLink: _linkChild, onCreate: _createChild);
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _children;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: children.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _FamilyHero(
                  childCount: children.length,
                  onLink: _linkChild,
                  onCreate: _createChild,
                );
              }
              return _ChildCard(
                child: children[index - 1],
                familyService: _service,
                onChanged: () => setState(_reload),
              );
            },
          ),
        );
      },
    ),
  );

  Future<void> _linkChild() async {
    final code = await _textDialog('Liên kết trẻ', 'Mã liên kết 6 số');
    if (code == null) return;
    await _run(() => _service.linkChild(code));
  }

  Future<void> _createChild() async {
    final result = await ChildSelectionDialog.show(
      context,
      initialCreateMode: true,
    );
    if (result != null) {
      setState(_reload);
    }
  }

  Future<String?> _textDialog(
    String title,
    String label, {
    bool obscure = false,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value?.isEmpty == true ? null : value;
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      setState(_reload);
      _message('Đã cập nhật thành công.');
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _FamilyHero extends StatelessWidget {
  const _FamilyHero({
    required this.childCount,
    required this.onLink,
    required this.onCreate,
  });

  final int childCount;
  final VoidCallback onLink;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFE46B), DuoColors.primaryYellow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2BEAB308),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.family_restroom_rounded, size: 38),
            const SizedBox(height: 14),
            const Text(
              'Cùng con tiến bộ mỗi ngày',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Bạn đang đồng hành cùng $childCount trẻ. Theo dõi và giao bài chỉ trong vài chạm.',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        );
        final actions = FilledButton.icon(
          style: FilledButton.styleFrom(
            fixedSize: const Size(200, 48),
            backgroundColor: DuoColors.textPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: onCreate,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Tạo tài khoản cho trẻ'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [info, const SizedBox(height: 18), actions],
          );
        }
        return Row(
          children: [
            Expanded(child: info),
            const SizedBox(width: 24),
            actions,
          ],
        );
      },
    ),
  );
}

class _EmptyFamily extends StatelessWidget {
  const _EmptyFamily({required this.onLink, required this.onCreate});
  final VoidCallback onLink;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.family_restroom_rounded,
            size: 72,
            color: DuoColors.darkYellow,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có hồ sơ trẻ em',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy tạo hồ sơ trẻ mới để bắt đầu đồng hành và giao bài học cho bé.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Tạo tài khoản cho trẻ'),
          ),
        ],
      ),
    ),
  );
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.familyService,
    required this.onChanged,
  });
  final Map<String, dynamic> child;
  final FamilyService familyService;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final id = child['userId'] as int;
    final name = child['fullName']?.toString() ?? 'Trẻ';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFF0E8D8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DuoColors.softYellow,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.child_care_rounded,
            color: DuoColors.darkYellow,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          'Trạng thái: ${child['status'] == 'Locked' ? 'Đã khóa' : 'Đang hoạt động'}',
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Quản lý tài khoản trẻ',
          onSelected: (action) => _handleAccountAction(context, action),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Sửa thông tin')),
            const PopupMenuItem(
              value: 'password',
              child: Text('Đặt lại mật khẩu'),
            ),
            PopupMenuItem(
              value: 'status',
              child: Text(
                child['status'] == 'Locked'
                    ? 'Mở khóa tài khoản'
                    : 'Khóa tài khoản',
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'unlink', child: Text('Hủy liên kết')),
          ],
        ),
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: familyService.getOverview(id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }
              final data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Hoàn thành: ${data['completedLessons']}/${data['startedLessons']}',
                        ),
                        Text('Chính xác: ${data['accuracy']}%'),
                        Text(
                          'Thời gian: ${data['estimatedLearningMinutes']} phút',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ActionCard(
                      icon: Icons.fact_check_rounded,
                      title: 'Giám sát hoạt động thực hành',
                      subtitle: 'Xem và xác nhận hoạt động trẻ đã hoàn thành',
                      onTap: () => _showActivitySheet(context, id, name),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.stars_rounded,
                      title: '⚡ Nhiệm vụ & Duyệt quà thưởng',
                      subtitle: 'Giao việc nhà, bài tập & duyệt quà thưởng cho bé',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParentTaskRewardScreen(
                              parentId: 1,
                              childId: id,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccountAction(BuildContext context, String action) async {
    final childId = child['userId'] as int;
    try {
      if (action == 'edit') {
        final name = await _prompt(
          context,
          'Sửa tên trẻ',
          'Họ tên',
          child['fullName']?.toString(),
        );
        if (name == null || !context.mounted) return;
        final email = await _prompt(
          context,
          'Sửa email trẻ',
          'Email',
          child['email']?.toString(),
        );
        if (email == null) return;
        await familyService.updateChild(childId, name, email);
      } else if (action == 'password') {
        final password = await _prompt(
          context,
          'Đặt lại mật khẩu',
          'Mật khẩu mới (ít nhất 8 ký tự)',
          null,
          obscure: true,
        );
        if (password == null) return;
        await familyService.resetChildPassword(childId, password);
      } else if (action == 'status') {
        await familyService.setChildStatus(
          childId,
          child['status'] == 'Locked' ? 'Active' : 'Locked',
        );
      } else if (action == 'unlink') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hủy liên kết trẻ?'),
            content: const Text(
              'Tài khoản trẻ và dữ liệu học tập vẫn được giữ lại.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hủy liên kết'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await familyService.unlinkChild(childId);
      }
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tài khoản trẻ.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<String?> _prompt(
    BuildContext context,
    String title,
    String label,
    String? initial, {
    bool obscure = false,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result == null || result.isEmpty ? null : result;
  }

  Future<void> _showActivitySheet(
    BuildContext context,
    int childId,
    String childName,
  ) async {
    final activity = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (_) =>
          _ActivityPicker(childId: childId, familyService: familyService),
    );
    if (activity == null || !context.mounted) return;
    final level = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Trẻ thực hiện thế nào?'),
        children: [
          for (final value in [
            'Tự thực hiện tốt',
            'Thực hiện khi được nhắc',
            'Cần luyện tập thêm',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Text(value),
            ),
        ],
      ),
    );
    if (level == null) return;
    try {
      await familyService.confirmActivity(
        childId,
        activity['situationId'] as int,
        '$childName: $level',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận hoạt động thực hành.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDF4), Color(0xFFFFF7D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE27A)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x1AEAB308), blurRadius: 10),
              ],
            ),
            child: Icon(icon, color: DuoColors.darkYellow, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 17,
            color: DuoColors.darkYellow,
          ),
        ],
      ),
    ),
  );
}

class _ActivityPicker extends StatelessWidget {
  const _ActivityPicker({required this.childId, required this.familyService});
  final int childId;
  final FamilyService familyService;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .72,
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: familyService.getPendingActivities(childId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hoạt động chờ xác nhận',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chỉ hiển thị hoạt động từ các bài trẻ đã hoàn thành.',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            'Hiện chưa có hoạt động nào cần xác nhận.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.task_alt_rounded,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  item['situationTitle']?.toString() ??
                                      'Bài học',
                                ),
                                subtitle: Text(
                                  item['questionText']?.toString() ?? '',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.pop(context, item),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
