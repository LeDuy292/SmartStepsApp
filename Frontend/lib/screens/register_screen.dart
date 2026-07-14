import 'dart:async';

import 'package:flutter/material.dart';

import '../services/local_profile_storage.dart';
import '../services/registration_avatar_service.dart';
import '../view_models/registration_view_model.dart';
import 'registration/registration_step_scaffold.dart';
import 'registration/registration_steps.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.profileStorage,
    required this.onRegistrationCompleted,
    this.viewModel,
  });

  final LocalProfileStorage profileStorage;
  final void Function(BuildContext context) onRegistrationCompleted;
  final RegistrationViewModel? viewModel;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegistrationViewModel _viewModel;
  late final bool _ownsViewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel =
        widget.viewModel ??
        RegistrationViewModel(profileStorage: widget.profileStorage);
    _nameController = TextEditingController(text: _viewModel.draft.childName);
    _emailController = TextEditingController(text: _viewModel.draft.email);
    _passwordController = TextEditingController(text: _viewModel.draft.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_viewModel.isLastStep) {
      _viewModel.next();
      return;
    }

    final completed = await _viewModel.submit();
    if (!mounted || !completed) {
      return;
    }
    widget.onRegistrationCompleted(context);
  }

  Future<bool> _handleBack() async {
    if (_viewModel.canGoBack) {
      _viewModel.back();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final avatars = RegistrationAvatarService.registrationAvatars;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return PopScope(
          canPop: !_viewModel.canGoBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _viewModel.canGoBack) {
              _viewModel.back();
            }
          },
          child: RegistrationStepScaffold(
            progress: _viewModel.progress,
            stepLabel:
                'Bước ${_viewModel.stepIndex + 1}/${_viewModel.stepCount}',
            canGoBack: _viewModel.canGoBack,
            onBack: () {
              unawaited(_handleBack());
            },
            primaryLabel: _viewModel.isLastStep ? 'Hoàn tất' : 'Tiếp tục',
            isLoading: _viewModel.isSaving,
            onPrimaryPressed: _viewModel.isSaving
                ? null
                : () {
                    unawaited(_handlePrimaryAction());
                  },
            message: _viewModel.validationMessage ?? _viewModel.submitError,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_viewModel.currentStep),
                child: _buildStep(avatars),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(List<RegistrationAvatar> avatars) {
    return switch (_viewModel.currentStep) {
      RegistrationStep.name => RegistrationNameStep(
        nameController: _nameController,
        emailController: _emailController,
        passwordController: _passwordController,
        onNameChanged: _viewModel.updateName,
        onEmailChanged: _viewModel.updateEmail,
        onPasswordChanged: _viewModel.updatePassword,
        isSurveyOnly: _viewModel.isSurveyOnly,
      ),
      RegistrationStep.age => RegistrationAgeStep(
        selectedAge: _viewModel.draft.age,
        onChanged: _viewModel.updateAge,
      ),
      RegistrationStep.gender => RegistrationGenderStep(
        selectedGender: _viewModel.draft.gender,
        onChanged: _viewModel.updateGender,
      ),
      RegistrationStep.goals => RegistrationGoalsStep(
        selectedGoals: _viewModel.draft.learningGoals,
        onToggle: _viewModel.toggleGoal,
      ),
      RegistrationStep.avatar => RegistrationAvatarStep(
        avatars: avatars,
        selectedStoragePath: _viewModel.draft.avatarStoragePath,
        onChanged: _viewModel.updateAvatar,
      ),
      RegistrationStep.terms => RegistrationTermsStep(
        draft: _viewModel.draft,
        avatars: avatars,
        accepted: _viewModel.draft.acceptedTerms,
        onChanged: _viewModel.updateAcceptedTerms,
      ),
    };
  }
}
