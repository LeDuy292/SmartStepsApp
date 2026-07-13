import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

Widget buildWebGoogleAuthButton() {
  return SizedBox(
    width: 42,
    height: 42,
    child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.icon,
        theme: web.GSIButtonTheme.outline,
      ),
    ),
  );
}
