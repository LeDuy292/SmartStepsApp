import 'package:flutter/material.dart';

import 'duo_components.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DuoPrimaryButton(label: label, icon: icon, onPressed: onPressed);
  }
}
