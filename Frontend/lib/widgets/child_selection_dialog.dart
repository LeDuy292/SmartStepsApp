import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/family_service.dart';
import '../services/local_profile_storage.dart';
import '../services/registration_avatar_service.dart';
import '../theme/duo_theme.dart';
import '../widgets/duo_components.dart';

const _childSkillOptions = [
  'Biết tự ăn uống',
  'Biết tự mặc quần áo',
  'Biết nói tên và địa chỉ nhà',
  'Biết gọi người lớn khi cần giúp đỡ',
  'Biết tránh xa ổ điện và vật nóng',
  'Biết nhìn hai bên trước khi qua đường',
  'Biết từ chối đi theo người lạ',
  'Biết giữ bình tĩnh khi bị lạc',
];

class ChildSelectionDialog extends StatefulWidget {
  const ChildSelectionDialog({
    super.key,
    required this.profileStorage,
    this.familyService,
    this.canDismiss = true,
    this.initialCreateMode = false,
  });

  final LocalProfileStorage profileStorage;
  final FamilyService? familyService;
  final bool canDismiss;
  final bool initialCreateMode;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    LocalProfileStorage? profileStorage,
    FamilyService? familyService,
    bool canDismiss = true,
    bool initialCreateMode = false,
  }) {
    final storage = profileStorage ?? LocalProfileStorage();
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) => ChildSelectionDialog(
        profileStorage: storage,
        familyService: familyService,
        canDismiss: canDismiss,
        initialCreateMode: initialCreateMode,
      ),
    );
  }

  @override
  State<ChildSelectionDialog> createState() => _ChildSelectionDialogState();
}

class _ChildSelectionDialogState extends State<ChildSelectionDialog> {
  late final FamilyService _familyService;
  late Future<List<Map<String, dynamic>>> _childrenFuture;
  late bool _isCreatingChild;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedAge = '6';
  String _selectedGender = 'Nam';
  String _selectedAvatar = 'avatars/cat.webp';
  final Set<String> _selectedSkills = {};
  int _createStep = 0;
  String? _createError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isCreatingChild = widget.initialCreateMode;
    _familyService = widget.familyService ?? FamilyService();
    _loadChildren();
  }

  void _loadChildren() {
    setState(() {
      _childrenFuture = _familyService.getChildren();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectChild(Map<String, dynamic> child) async {
    final childName = child['fullName']?.toString().trim();
    final profile = ChildProfile(
      childName: childName == null || childName.isEmpty ? 'Bé' : childName,
      age: _selectedAge,
      gender: _selectedGender,
      avatarStoragePath: _selectedAvatar,
      learningGoals: const [],
      acceptedTerms: true,
      completedAt: DateTime.now(),
    );

    await widget.profileStorage.saveProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pop(child);
  }

  Future<void> _handleCreateChild() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _createError = 'Vui lòng nhập họ và tên của bé.';
      });
      return;
    }

    if (_selectedSkills.isEmpty) {
      setState(() {
        _createStep = 2;
        _createError = 'Hãy chọn ít nhất một việc bé đã biết làm.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _createError = null;
    });

    try {
      await _familyService.createChild(name, '', '12345678');

      final child = {'fullName': name};

      final profile = ChildProfile(
        childName: name,
        age: _selectedAge,
        gender: _selectedGender,
        avatarStoragePath: _selectedAvatar,
        learningGoals: _selectedSkills.toList(growable: false),
        acceptedTerms: true,
        completedAt: DateTime.now(),
      );

      await widget.profileStorage.saveProfile(profile);

      _nameController.clear();
      if (!mounted) return;

      Navigator.of(context).pop(child);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _createError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 580),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_rounded,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isCreatingChild ? 'Tạo hồ sơ bé mới' : 'Chọn Trẻ em',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: DuoColors.textPrimary,
                    ),
                  ),
                ),
                if (widget.canDismiss && !_isCreatingChild)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isCreatingChild)
              _buildCreateChildForm()
            else
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _childrenFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Không thể tải danh sách trẻ: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final children = snapshot.data ?? const [];

                    if (children.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.child_care_rounded,
                            size: 64,
                            color: DuoColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Bạn chưa tạo hồ sơ trẻ nào.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DuoColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tạo hồ sơ để bắt đầu hành trình học tập cùng bé!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: DuoColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          DuoPrimaryButton(
                            label: 'Tạo hồ sơ trẻ ngay',
                            onPressed: () {
                              setState(() {
                                _isCreatingChild = true;
                              });
                            },
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Vui lòng chọn hồ sơ trẻ em để vào ứng dụng:',
                          style: TextStyle(
                            fontSize: 14,
                            color: DuoColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: children.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final child = children[index];
                              final name =
                                  child['fullName']?.toString() ?? 'Bé';
                              final email = child['email']?.toString() ?? '';

                              return InkWell(
                                onTap: () => _selectChild(child),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: DuoColors.border,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: DuoColors.softYellow,
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'B',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: DuoColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: DuoColors.textPrimary,
                                              ),
                                            ),
                                            if (email.isNotEmpty)
                                              Text(
                                                email,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      DuoColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: DuoColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isCreatingChild = true;
                                  });
                                },
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Tạo hồ sơ mới'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop({'mode': 'parent_workspace'});
                                },
                                icon: const Icon(Icons.family_restroom_rounded),
                                label: const Text('Khu vực Phụ huynh'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  backgroundColor: DuoColors.darkYellow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateChildForm() {
    final avatars = RegistrationAvatarService.registrationAvatars;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(3, (index) {
              final active = index <= _createStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: active ? DuoColors.darkYellow : DuoColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Bước ${_createStep + 1}/3 · ${switch (_createStep) {
              0 => 'Thông tin của bé',
              1 => 'Độ tuổi của bé',
              _ => 'Bé đã biết làm gì?',
            }}',
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: switch (_createStep) {
                0 => Column(
                  children: [
                    TextField(
                      key: const ValueKey('create-child-name'),
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên của bé *',
                        hintText: 'Ví dụ: Nguyễn Văn A',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                1 => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bé bao nhiêu tuổi?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int age = 4; age <= 10; age++)
                          ChoiceChip(
                            label: Text('$age tuổi'),
                            selected: _selectedAge == '$age',
                            onSelected: (_) =>
                                setState(() => _selectedAge = '$age'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Giới tính của bé',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final gender in ['Nam', 'Nữ', 'Khác'])
                          ChoiceChip(
                            label: Text(gender),
                            selected: _selectedGender == gender,
                            onSelected: (_) =>
                                setState(() => _selectedGender = gender),
                          ),
                      ],
                    ),
                  ],
                ),
                _ => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn những việc bé đã có thể tự làm',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (final skill in _childSkillOptions)
                      CheckboxListTile(
                        key: ValueKey('create-child-skill-$skill'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(skill),
                        value: _selectedSkills.contains(skill),
                        onChanged: (_) {
                          setState(() {
                            _selectedSkills.contains(skill)
                                ? _selectedSkills.remove(skill)
                                : _selectedSkills.add(skill);
                            _createError = null;
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chọn avatar cho bé',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: avatars.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = avatars[index];
                          final selected = _selectedAvatar == item.storagePath;
                          return GestureDetector(
                            onTap: () => setState(
                              () => _selectedAvatar = item.storagePath,
                            ),
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? DuoColors.darkYellow
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Image.asset(
                                item.assetPath,
                                width: 36,
                                height: 36,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(item.label.substring(0, 1)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              },
            ),
          ),
          if (_createError != null) ...[
            const SizedBox(height: 8),
            Text(
              _createError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_createStep > 0) {
                            setState(() {
                              _createStep--;
                              _createError = null;
                            });
                          } else {
                            setState(() {
                              _isCreatingChild = false;
                              _createError = null;
                            });
                          }
                        },
                  child: Text(_createStep == 0 ? 'Hủy' : 'Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_createStep == 0 &&
                              _nameController.text.trim().isEmpty) {
                            setState(() {
                              _createError = 'Vui lòng nhập họ và tên của bé.';
                            });
                            return;
                          }
                          if (_createStep < 2) {
                            setState(() {
                              _createStep++;
                              _createError = null;
                            });
                          } else {
                            _handleCreateChild();
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_createStep == 2 ? 'Tạo hồ sơ' : 'Tiếp tục'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
