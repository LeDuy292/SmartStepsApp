import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/local_profile_storage.dart';
import '../services/registration_avatar_service.dart';
import '../theme/duo_theme.dart';
import '../widgets/duo_components.dart';
import '../widgets/child_selection_dialog.dart';
import 'family_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profileStorage,
    required this.onLogout,
    this.onManagePremium,
    this.onChildSelected,
  });

  final LocalProfileStorage profileStorage;
  final void Function(BuildContext context) onLogout;
  final VoidCallback? onManagePremium;
  final void Function(Map<String, dynamic>? selected)? onChildSelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ChildProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.profileStorage.readProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileStorage != widget.profileStorage) {
      _profileFuture = widget.profileStorage.readProfile();
    }
  }

  Future<void> _showParentGate(BuildContext context) async {
    final now = DateTime.now();
    final num1 = 3 + (now.second % 6);
    final num2 = 2 + (now.millisecond % 5);
    final correctAnswer = num1 + num2;

    final controller = TextEditingController();
    String? errorText;

    final passed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: DuoColors.darkYellow),
              SizedBox(width: 8),
              Text('Khóa Phụ huynh', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dành riêng cho Phụ huynh. Vui lòng tính nhẩm phép tính bên dưới:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DuoColors.softYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$num1  +  $num2  =  ?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DuoColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nhập kết quả',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (int.tryParse(value.trim()) == correctAnswer) {
                    Navigator.pop(context, true);
                  } else {
                    setDialogState(() {
                      errorText = 'Kết quả chưa đúng, vui lòng thử lại.';
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (int.tryParse(controller.text.trim()) == correctAnswer) {
                  Navigator.pop(context, true);
                } else {
                  setDialogState(() {
                    errorText = 'Kết quả chưa đúng, vui lòng thử lại.';
                  });
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (passed == true && context.mounted) {
      final selected = await ChildSelectionDialog.show(
        context,
        profileStorage: widget.profileStorage,
      );
      if (!mounted) return;
      if (widget.onChildSelected != null) {
        widget.onChildSelected!(selected);
      } else if (selected?['mode'] == 'parent_workspace') {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FamilyScreen(),
          ),
        );
      } else if (selected != null) {
        setState(() {
          _profileFuture = widget.profileStorage.readProfile();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('profile-screen'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<ChildProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return RefreshIndicator(
              color: DuoColors.success,
              onRefresh: () async {
                setState(() {
                  _profileFuture = widget.profileStorage.readProfile();
                });
                await _profileFuture;
              },
              child: ListView(
                key: const ValueKey('basic-info-page'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  const _BasicInfoHeader(),
                  const SizedBox(height: 18),
                  _ChildSummaryCard(profile: profile, isLoading: isLoading),
                  const SizedBox(height: 16),
                  _InfoSection(
                    title: 'Hồ sơ của bé',
                    icon: Icons.face_rounded,
                    rows: [
                      _InfoRowData('Tên của bé', _displayName(profile)),
                      _InfoRowData(
                        'Độ tuổi',
                        profile?.displayAge ?? 'Chưa cập nhật',
                      ),
                      _InfoRowData(
                        'Giới tính',
                        _nonEmpty(profile?.gender, 'Chưa cập nhật'),
                      ),
                      _InfoRowData(
                        'Mục tiêu chính',
                        profile?.primaryGoal ?? 'Chưa cập nhật',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _LearningGoalsSection(profile: profile),
                  const SizedBox(height: 14),
                  _InfoSection(
                    title: 'Ứng dụng',
                    icon: Icons.apps_rounded,
                    rows: [
                      const _InfoRowData('Tên ứng dụng', 'SmartSteps'),
                      const _InfoRowData('Phiên bản', '1.0.0'),
                      const _InfoRowData('Chế độ dữ liệu', 'Offline dùng thử'),
                      _InfoRowData(
                        'Gói hiện tại',
                        profile?.planName ?? 'Miễn phí',
                      ),
                      _InfoRowData(
                        'Hồ sơ local',
                        profile == null ? 'Chưa có file' : 'Đã lưu trên máy',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<String?>(
                    future: AuthService().getUserRole(),
                    builder: (context, roleSnapshot) {
                      if (roleSnapshot.data != 'Parent') {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _showParentGate(context),
                              icon: const Icon(Icons.lock_outline_rounded),
                              label: const Text('Khu vực Phụ huynh (Khóa Phụ huynh)'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: DuoColors.darkYellow,
                              ),
                            ),
                            if (widget.onManagePremium != null) ...[
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: widget.onManagePremium,
                                icon: const Icon(
                                  Icons.workspace_premium_rounded,
                                ),
                                label: const Text(
                                  'Thanh toán và quản lý Premium',
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  _ProfileActions(
                    onRefresh: () {
                      setState(() {
                        _profileFuture = widget.profileStorage.readProfile();
                      });
                    },
                    onLogout: _handleLogout,
                    onFeatureUnavailable: () =>
                        _showFeatureInDevelopment(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutConfirmation(context);
    if (shouldLogout != true || !mounted) {
      return;
    }

    await widget.profileStorage.clearProfile();
    if (!mounted) {
      return;
    }

    widget.onLogout(context);
  }

  Future<void> _showParentLinkCode() async {
    try {
      final result = await FamilyService().createLinkCode();
      if (!mounted) return;
      final code = result['code']?.toString() ?? '';
      final expiresAt = DateTime.tryParse(
        result['expiresAt']?.toString() ?? '',
      );
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.family_restroom_rounded, size: 42),
          title: const Text('Mã liên kết phụ huynh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Phụ huynh nhập mã này trong trang Quản lý trẻ.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                expiresAt == null
                    ? 'Mã có hiệu lực trong 15 phút.'
                    : 'Mã hết hạn lúc ${TimeOfDay.fromDateTime(expiresAt.toLocal()).format(context)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: DuoColors.textSecondary),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được mã liên kết: $error')),
      );
    }
  }
}

class _BasicInfoHeader extends StatelessWidget {
  const _BasicInfoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DuoColors.softYellow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DuoColors.border, width: 2),
          ),
          child: const Icon(
            Icons.badge_rounded,
            color: DuoColors.darkYellow,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin cơ bản',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                'Đọc từ hồ sơ đã lưu trên máy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildSummaryCard extends StatelessWidget {
  const _ChildSummaryCard({required this.profile, required this.isLoading});

  final ChildProfile? profile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      color: DuoColors.background,
      borderColor: DuoColors.border,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: ClipOval(
              child: isLoading
                  ? const ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: DuoColors.darkYellow,
                        ),
                      ),
                    )
                  : _ProfileAvatar(profile: profile),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(profile),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  profile == null
                      ? 'Chưa có thông tin khảo sát'
                      : '${profile!.displayAge} • ${profile!.primaryGoal}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                DuoProgressBar(value: profile == null ? 0.12 : 1, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final ChildProfile? profile;

  @override
  Widget build(BuildContext context) {
    final avatar = RegistrationAvatarService.findByStoragePath(
      profile?.avatarStoragePath,
    );
    if (avatar == null) {
      return const ColoredBox(
        color: Colors.white,
        child: Icon(
          Icons.child_care_rounded,
          color: DuoColors.darkYellow,
          size: 44,
        ),
      );
    }

    final imageUrl = avatar.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        avatar.assetPath,
        key: const ValueKey('profile-avatar-image'),
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      imageUrl,
      key: const ValueKey('profile-avatar-image'),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          Image.asset(avatar.assetPath, fit: BoxFit.cover),
    );
  }
}

class _LearningGoalsSection extends StatelessWidget {
  const _LearningGoalsSection({required this.profile});

  final ChildProfile? profile;

  @override
  Widget build(BuildContext context) {
    final goals = profile?.learningGoals ?? const <String>[];

    return DuoCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      borderColor: DuoColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                color: DuoColors.darkYellow,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mục tiêu học đã chọn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            const _EmptyProfileNotice()
          else
            for (final goal in goals) ...[
              _GoalChip(label: goal),
              if (goal != goals.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _EmptyProfileNotice extends StatelessWidget {
  const _EmptyProfileNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DuoColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.border),
      ),
      child: Text(
        'Chưa có dữ liệu khảo sát. Hãy hoàn tất form ban đầu để hồ sơ hiển thị ở đây.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: DuoColors.softYellow,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: DuoColors.success,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
      borderColor: DuoColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: DuoColors.darkYellow, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final row in rows) _BasicInfoRow(data: row),
        ],
      ),
    );
  }
}

class _BasicInfoRow extends StatelessWidget {
  const _BasicInfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3E7BA), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DuoColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              data.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.onRefresh,
    required this.onLogout,
    required this.onFeatureUnavailable,
  });

  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback onFeatureUnavailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DuoPrimaryButton(
          label: 'Tải lại thông tin',
          icon: Icons.refresh_rounded,
          onPressed: onRefresh,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onFeatureUnavailable,
          icon: const Icon(Icons.privacy_tip_rounded, size: 21),
          label: const Text(
            'Dữ liệu lưu trên máy',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            foregroundColor: DuoColors.textPrimary,
            side: const BorderSide(color: DuoColors.border, width: 2),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, size: 21),
          label: const Text(
            'Đăng xuất',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            foregroundColor: const Color(0xFFBA1A1A),
            side: const BorderSide(color: Color(0xFFFFDAD6), width: 2),
            backgroundColor: const Color(0xFFFFFBFF),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRowData {
  const _InfoRowData(this.label, this.value);

  final String label;
  final String value;
}

String _displayName(ChildProfile? profile) {
  return _nonEmpty(profile?.childName, 'Chưa có tên bé');
}

String _nonEmpty(String? value, String fallback) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return fallback;
  }

  return text;
}

void _showFeatureInDevelopment(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tính năng đang được phát triển.')),
  );
}

Future<bool?> _showLogoutConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      );
    },
  );
}
