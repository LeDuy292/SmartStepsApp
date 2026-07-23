import 'package:flutter/material.dart';

import '../../models/registration_draft.dart';
import '../../services/registration_avatar_service.dart';
import '../../theme/duo_theme.dart';
import '../../view_models/registration_view_model.dart';
import '../../widgets/smartsteps_press_effect.dart';

const registrationLearningGoals = [
  'Biết quan sát và đặt câu hỏi',
  'Tư duy logic qua tình huống thực tế',
  'Học cách thử sai và sửa lỗi',
  'Tự tin nói chuyện với người khác',
  'Biết xử lý khi bị lạc',
  'Nhận biết người lạ nguy hiểm',
  'Nhận biết tình huống khẩn cấp',
  'Học quản lý thời gian đơn giản',
];

class RegistrationNameStep extends StatelessWidget {
  const RegistrationNameStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.selectedRole,
    required this.onRoleChanged,
    this.isSurveyOnly = false,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final bool isSurveyOnly;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Tạo tài khoản',
      subtitle: 'Thông tin này dùng để đăng nhập và lưu tiến độ.',
      mascotAsset: 'assets/images/mascot/mascot-cat-happy-wave.webp',
      child: Column(
        children: [
          TextField(
            key: const ValueKey('registration-name-field'),
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 40,
            onChanged: onNameChanged,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: _inputDecoration(
              'Họ tên Phụ huynh',
            ),
          ),
          if (!isSurveyOnly) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('registration-email-field'),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: onEmailChanged,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: _inputDecoration(
                selectedRole == 'Parent'
                    ? 'Email phụ huynh'
                    : 'Email tài khoản trẻ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('registration-password-field'),
              controller: passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onChanged: onPasswordChanged,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: _inputDecoration('Mật khẩu'),
            ),
          ],
        ],
      ),
    );
  }
}

class RegistrationAgeStep extends StatelessWidget {
  const RegistrationAgeStep({
    super.key,
    required this.selectedAge,
    required this.onChanged,
  });

  final String selectedAge;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Bé bao nhiêu tuổi?',
      subtitle: 'SmartSteps sẽ điều chỉnh cách diễn đạt phù hợp với độ tuổi.',
      mascotAsset: 'assets/images/mascot/mascot-cat-speaking.webp',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 520 ? 5 : 3;
          return GridView.builder(
            key: const ValueKey('registration-age-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: registrationMaxAge - registrationMinAge + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final age = '${index + registrationMinAge}';
              return _ChoiceButton(
                key: ValueKey('registration-age-$age'),
                label: age,
                selected: selectedAge == age,
                onPressed: () => onChanged(age),
              );
            },
          );
        },
      ),
    );
  }
}

class RegistrationGenderStep extends StatelessWidget {
  const RegistrationGenderStep({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  final String? selectedGender;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = ['Nam', 'Nữ', 'Không muốn trả lời'];
    return _StepFrame(
      title: 'Giới tính của bé?',
      subtitle: 'Thông tin này giúp hồ sơ của bé đầy đủ hơn.',
      mascotAsset: 'assets/images/mascot/mascot-cat-confident.webp',
      child: Column(
        children: [
          for (final option in options) ...[
            _ChoiceButton(
              key: ValueKey('registration-gender-$option'),
              label: option,
              selected: selectedGender == option,
              onPressed: () => onChanged(option),
            ),
            if (option != options.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class RegistrationGoalsStep extends StatelessWidget {
  const RegistrationGoalsStep({
    super.key,
    required this.selectedGoals,
    required this.onToggle,
  });

  final Set<String> selectedGoals;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Bé muốn học điều gì?',
      subtitle: 'Có thể chọn nhiều mục tiêu. Bạn có thể thay đổi sau.',
      mascotAsset: 'assets/images/mascot/mascot-cat-singing.webp',
      child: Column(
        children: [
          for (final goal in registrationLearningGoals) ...[
            _ChoiceButton(
              key: ValueKey('registration-goal-$goal'),
              label: goal,
              selected: selectedGoals.contains(goal),
              leading: selectedGoals.contains(goal)
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              onPressed: () => onToggle(goal),
            ),
            if (goal != registrationLearningGoals.last)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class RegistrationAvatarStep extends StatelessWidget {
  const RegistrationAvatarStep({
    super.key,
    required this.avatars,
    required this.selectedStoragePath,
    required this.onChanged,
  });

  final List<RegistrationAvatar> avatars;
  final String? selectedStoragePath;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Chọn avatar cho bé',
      subtitle: 'Avatar con vật này sẽ đại diện cho bé trong hồ sơ SmartSteps.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 4 : 2;
          return GridView.builder(
            key: const ValueKey('registration-avatar-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: avatars.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              final selected = selectedStoragePath == avatar.storagePath;
              return Semantics(
                button: true,
                selected: selected,
                label: avatar.label,
                child: SmartStepsPressEffect(
                  child: InkWell(
                    key: ValueKey('registration-avatar-${avatar.storagePath}'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onChanged(avatar.storagePath),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: avatar.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? DuoColors.textPrimary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: _AvatarImage(avatar: avatar)),
                          const SizedBox(height: 8),
                          Text(
                            avatar.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DuoColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RegistrationTermsStep extends StatelessWidget {
  const RegistrationTermsStep({
    super.key,
    required this.draft,
    required this.avatars,
    required this.accepted,
    required this.onChanged,
  });

  final RegistrationDraft draft;
  final List<RegistrationAvatar> avatars;
  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final avatar = avatars.where(
      (item) => item.storagePath == draft.avatarStoragePath,
    );
    final avatarLabel = avatar.isEmpty ? 'Chưa chọn' : avatar.first.label;

    return _StepFrame(
      title: 'Sẵn sàng bắt đầu',
      subtitle: draft.role == 'Parent'
          ? 'Kiểm tra lại tài khoản phụ huynh trước khi hoàn tất.'
          : 'Phụ huynh kiểm tra lại hồ sơ trước khi lưu trên thiết bị.',
      mascotAsset: 'assets/images/mascot/mascot-cat-happy.webp',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DuoColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DuoColors.border, width: 2),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Tên', value: draft.childName.trim()),
                _SummaryRow(
                  label: 'Vai trò',
                  value: draft.role == 'Parent' ? 'Phụ huynh' : 'Trẻ em',
                ),
                if (draft.role == 'Child') ...[
                  _SummaryRow(label: 'Tuổi', value: '${draft.age} tuổi'),
                  _SummaryRow(label: 'Giới tính', value: draft.gender ?? ''),
                  _SummaryRow(label: 'Avatar', value: avatarLabel),
                  _SummaryRow(
                    label: 'Mục tiêu',
                    value: '${draft.learningGoals.length} mục tiêu đã chọn',
                    showDivider: false,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SmartStepsPressEffect(
            child: InkWell(
              key: const ValueKey('registration-terms-toggle'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(!accepted),
              child: Container(
                constraints: const BoxConstraints(minHeight: 70),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accepted
                      ? const Color(0xFFEAF8DF)
                      : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accepted
                        ? DuoColors.success
                        : const Color(0xFFD8D8D8),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: accepted,
                      onChanged: (value) => onChanged(value ?? false),
                      activeColor: DuoColors.success,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tôi là phụ huynh/người giám hộ và đồng ý với điều khoản sử dụng.',
                        style: TextStyle(
                          color: DuoColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showTerms(context),
            child: const Text('Đọc điều khoản sử dụng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTerms(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Điều khoản sử dụng'),
          content: const SingleChildScrollView(
            child: Text(
              'SmartSteps dùng thông tin hồ sơ để cá nhân hóa trải nghiệm học tập an toàn cho bé. Phụ huynh chịu trách nhiệm kiểm tra thông tin trước khi sử dụng. Nội dung trong ứng dụng hỗ trợ giáo dục kỹ năng an toàn và không thay thế hướng dẫn trực tiếp từ người lớn.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.mascotAsset,
  });

  final String title;
  final String subtitle;
  final String? mascotAsset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mascotAsset != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(mascotAsset!, width: 116, height: 116),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 10),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return SmartStepsPressEffect(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          alignment: Alignment.centerLeft,
          foregroundColor: DuoColors.textPrimary,
          backgroundColor: selected ? const Color(0xFFEAF8DF) : Colors.white,
          side: BorderSide(
            color: selected ? DuoColors.success : const Color(0xFFD8D8D8),
            width: selected ? 2.5 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              Icon(leading, size: 23),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.avatar});

  final RegistrationAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatar.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(avatar.assetPath, fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Image.asset(avatar.assetPath, fit: BoxFit.cover),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DuoColors.textPrimary,
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: DuoColors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DuoColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: DuoColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: DuoColors.border, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: DuoColors.success, width: 2.5),
    ),
  );
}
