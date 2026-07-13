import 'child_profile.dart';

class RegistrationDraft {
  const RegistrationDraft({
    this.childName = '',
    this.age = '',
    this.gender,
    this.learningGoals = const {},
    this.avatarStoragePath,
    this.acceptedTerms = false,
  });

  final String childName;
  final String age;
  final String? gender;
  final Set<String> learningGoals;
  final String? avatarStoragePath;
  final bool acceptedTerms;

  RegistrationDraft copyWith({
    String? childName,
    String? age,
    String? gender,
    Set<String>? learningGoals,
    String? avatarStoragePath,
    bool? acceptedTerms,
  }) {
    return RegistrationDraft(
      childName: childName ?? this.childName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      learningGoals: learningGoals ?? this.learningGoals,
      avatarStoragePath: avatarStoragePath ?? this.avatarStoragePath,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    );
  }

  ChildProfile toProfile({DateTime? completedAt}) {
    return ChildProfile(
      childName: childName.trim(),
      age: age.trim(),
      gender: gender?.trim() ?? '',
      learningGoals: learningGoals.toList(growable: false),
      acceptedTerms: acceptedTerms,
      completedAt: completedAt ?? DateTime.now(),
      avatarStoragePath: avatarStoragePath,
    );
  }
}
