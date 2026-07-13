import 'package:flutter/foundation.dart';

bool get smartStepsIsIosWeb =>
    kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
