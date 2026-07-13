import 'package:flutter/foundation.dart';

import '../models/registration_draft.dart';
import '../services/local_profile_storage.dart';

enum RegistrationStep { name, age, gender, goals, avatar, terms }

enum RegistrationSubmitStatus { idle, saving, success, failure }

const registrationMinAge = 4;
const registrationMaxAge = 10;

class RegistrationViewModel extends ChangeNotifier {
  RegistrationViewModel({
    required LocalProfileStorage profileStorage,
    RegistrationDraft initialDraft = const RegistrationDraft(),
  }) : _profileStorage = profileStorage,
       _draft = initialDraft;

  final LocalProfileStorage _profileStorage;

  RegistrationDraft _draft;
  int _stepIndex = 0;
  String? _validationMessage;
  String? _submitError;
  RegistrationSubmitStatus _submitStatus = RegistrationSubmitStatus.idle;

  RegistrationDraft get draft => _draft;
  RegistrationStep get currentStep => RegistrationStep.values[_stepIndex];
  int get stepIndex => _stepIndex;
  int get stepCount => RegistrationStep.values.length;
  double get progress => (_stepIndex + 1) / stepCount;
  bool get canGoBack => _stepIndex > 0;
  bool get isLastStep => _stepIndex == stepCount - 1;
  bool get isSaving => _submitStatus == RegistrationSubmitStatus.saving;
  RegistrationSubmitStatus get submitStatus => _submitStatus;
  String? get validationMessage => _validationMessage;
  String? get submitError => _submitError;

  void updateName(String value) {
    _draft = _draft.copyWith(childName: value);
    _clearMessages();
  }

  void updateAge(String value) {
    _draft = _draft.copyWith(age: value);
    _clearMessages();
  }

  void updateGender(String value) {
    _draft = _draft.copyWith(gender: value);
    _clearMessages();
  }

  void toggleGoal(String goal) {
    final goals = {..._draft.learningGoals};
    if (!goals.add(goal)) {
      goals.remove(goal);
    }
    _draft = _draft.copyWith(learningGoals: goals);
    _clearMessages();
  }

  void updateAvatar(String storagePath) {
    _draft = _draft.copyWith(avatarStoragePath: storagePath);
    _clearMessages();
  }

  void updateAcceptedTerms(bool value) {
    _draft = _draft.copyWith(acceptedTerms: value);
    _clearMessages();
  }

  bool next() {
    final message = _validateCurrentStep();
    if (message != null) {
      _validationMessage = message;
      notifyListeners();
      return false;
    }

    if (!isLastStep) {
      _stepIndex += 1;
      _clearMessages();
    }
    return true;
  }

  void back() {
    if (!canGoBack || isSaving) {
      return;
    }
    _stepIndex -= 1;
    _clearMessages();
  }

  Future<bool> submit() async {
    final message = _validateCurrentStep();
    if (message != null || !isLastStep || isSaving) {
      _validationMessage = message;
      notifyListeners();
      return false;
    }

    _submitStatus = RegistrationSubmitStatus.saving;
    _submitError = null;
    notifyListeners();

    try {
      await _profileStorage.saveProfile(_draft.toProfile());
      _submitStatus = RegistrationSubmitStatus.success;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      debugPrint('SmartSteps registration save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _submitStatus = RegistrationSubmitStatus.failure;
      _submitError = 'Chưa lưu được hồ sơ. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  String? _validateCurrentStep() {
    return switch (currentStep) {
      RegistrationStep.name => _validateName(),
      RegistrationStep.age => _validateAge(),
      RegistrationStep.gender =>
        _draft.gender == null ? 'Hãy chọn giới tính của bé.' : null,
      RegistrationStep.goals =>
        _draft.learningGoals.isEmpty
            ? 'Hãy chọn ít nhất một mục tiêu học.'
            : null,
      RegistrationStep.avatar =>
        _draft.avatarStoragePath == null ? 'Hãy chọn avatar cho bé.' : null,
      RegistrationStep.terms =>
        !_draft.acceptedTerms
            ? 'Phụ huynh cần đồng ý điều khoản để tiếp tục.'
            : null,
    };
  }

  String? _validateName() {
    final name = _draft.childName.trim();
    if (name.isEmpty) {
      return 'Hãy nhập tên của bé.';
    }
    if (name.length < 2) {
      return 'Tên cần có ít nhất 2 ký tự.';
    }
    return null;
  }

  String? _validateAge() {
    final age = int.tryParse(_draft.age.trim());
    if (age == null) {
      return 'Hãy chọn độ tuổi của bé.';
    }
    if (age < registrationMinAge || age > registrationMaxAge) {
      return 'SmartSteps hiện phù hợp với trẻ từ 4 đến 10 tuổi.';
    }
    return null;
  }

  void _clearMessages() {
    _validationMessage = null;
    _submitError = null;
    if (_submitStatus == RegistrationSubmitStatus.failure) {
      _submitStatus = RegistrationSubmitStatus.idle;
    }
    notifyListeners();
  }
}
