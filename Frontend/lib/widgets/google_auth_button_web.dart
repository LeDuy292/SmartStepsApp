import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

Widget buildWebGoogleAuthButton() {
  return const _WebGoogleAuthButton();
}

class _WebGoogleAuthButton extends StatefulWidget {
  const _WebGoogleAuthButton();

  @override
  State<_WebGoogleAuthButton> createState() => _WebGoogleAuthButtonState();
}

class _WebGoogleAuthButtonState extends State<_WebGoogleAuthButton> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
            .renderButton(
              configuration: web.GSIButtonConfiguration(
                type: web.GSIButtonType.icon,
                theme: web.GSIButtonTheme.outline,
                size: web.GSIButtonSize.large,
                shape: web.GSIButtonShape.pill,
              ),
            ),
      ),
    );
  }
}
