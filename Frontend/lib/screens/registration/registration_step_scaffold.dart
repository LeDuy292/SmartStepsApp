import 'package:flutter/material.dart';

import '../../theme/duo_theme.dart';
import '../../widgets/duo_components.dart';

class RegistrationStepScaffold extends StatelessWidget {
  const RegistrationStepScaffold({
    super.key,
    required this.progress,
    required this.stepLabel,
    required this.canGoBack,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final double progress;
  final String stepLabel;
  final bool canGoBack;
  final VoidCallback onBack;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      key: const ValueKey('registration-wizard'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 40.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              key: const ValueKey('registration-back-button'),
                              onPressed: canGoBack
                                  ? onBack
                                  : () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Quay lại',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DuoProgressBar(
                              value: progress,
                              height: 14,
                              color: DuoColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            stepLabel,
                            style: const TextStyle(
                              color: DuoColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('registration-step-scroll'),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          24,
                        ),
                        child: child,
                      ),
                    ),
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 160),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        10,
                        horizontalPadding,
                        bottomInset > 0 ? 10 : 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: message == null
                                ? const SizedBox(
                                    key: ValueKey('registration-no-message'),
                                  )
                                : Padding(
                                    key: const ValueKey(
                                      'registration-error-message',
                                    ),
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      message!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFBA1A1A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(
                            height: 56,
                            child: DuoPrimaryButton(
                              label: isLoading ? 'Đang lưu...' : primaryLabel,
                              onPressed: onPrimaryPressed,
                              backgroundColor: DuoColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
