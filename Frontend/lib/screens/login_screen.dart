import 'package:flutter/material.dart';

import '../theme/duo_theme.dart';
import '../widgets/smartsteps_press_effect.dart';
import '../services/local_profile_storage.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.profileStorage,
    required this.onLogin,
    required this.onRegistrationCompleted,
  });

  final LocalProfileStorage profileStorage;
  final void Function(BuildContext context) onLogin;
  final void Function(BuildContext context) onRegistrationCompleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.primaryYellow,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = (width / 412).clamp(0.86, 1.16);

            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: DuoColors.primaryYellow,
                    ),
                    child: Align(
                      alignment: const Alignment(0, -0.72),
                      child: Image.asset(
                        'assets/images/logo/logo smartstep-01.webp',
                        width: 190 * scale,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: (height * 0.63).clamp(520.0, 590.0),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        51 * scale,
                        54,
                        47 * scale,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BẮT ĐẦU CÁC KHÓA HỌC CỦA BẠN',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Bạn chưa có tài khoản?',
                                  style: TextStyle(
                                    color: Color(0xFF7A7A7A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              SmartStepsPressEffect(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder<void>(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => RegisterScreen(
                                              profileStorage: profileStorage,
                                              onRegistrationCompleted:
                                                  onRegistrationCompleted,
                                            ),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              final curvedAnimation =
                                                  CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeOutCubic,
                                                    reverseCurve:
                                                        Curves.easeInCubic,
                                                  );

                                              return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, 1),
                                                  end: Offset.zero,
                                                ).animate(curvedAnimation),
                                                child: child,
                                              );
                                            },
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(64, 34),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Đăng ký',
                                    style: TextStyle(
                                      color: Color(0xFFFF3F3F),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const _LoginInput(label: 'Email'),
                          const SizedBox(height: 13),
                          const _LoginInput(label: 'Mật khẩu', obscure: true),
                          const SizedBox(height: 11),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SmartStepsPressEffect(
                              child: TextButton(
                                onPressed: () =>
                                    _showFeatureInDevelopment(context),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Quên mật khẩu',
                                  style: TextStyle(
                                    color: Color(0xFFBA1A1A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 23),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: SmartStepsPressEffect(
                              child: FilledButton(
                                key: const ValueKey('login-submit-button'),
                                onPressed: () {
                                  onLogin(context);
                                },
                                style: FilledButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: DuoColors.primaryYellow,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('Đăng nhập'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const _SocialDivider(),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialButton(
                                label: 'Google',
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: Color(0xFF4285F4),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(width: 22),
                              _SocialButton(
                                label: 'Facebook',
                                child: Text(
                                  'f',
                                  style: TextStyle(
                                    color: Color(0xFF1877F2),
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _showFeatureInDevelopment(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tính năng đang được phát triển.')),
  );
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({required this.label, this.obscure = false});

  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.black, thickness: 2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            'Đăng nhập với',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.black, thickness: 2)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: 74,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
