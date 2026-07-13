import 'package:flutter/material.dart';

import 'supabase_config.dart';

class RegistrationAvatar {
  const RegistrationAvatar({
    required this.label,
    required this.color,
    required this.storagePath,
    required this.assetPath,
    this.imageUrl,
  });

  final String label;
  final Color color;
  final String storagePath;
  final String assetPath;
  final String? imageUrl;
}

class RegistrationAvatarService {
  const RegistrationAvatarService._();

  static const _avatarDefinitions = [
    RegistrationAvatar(
      label: 'Mèo',
      color: Color(0xFFE8D7FF),
      storagePath: 'avatars/cat.webp',
      assetPath: 'assets/images/avatars/cat.webp',
    ),
    RegistrationAvatar(
      label: 'Chó',
      color: Color(0xFFFFF0AE),
      storagePath: 'avatars/dog.webp',
      assetPath: 'assets/images/avatars/dog.webp',
    ),
    RegistrationAvatar(
      label: 'Voi',
      color: Color(0xFFD8F1FF),
      storagePath: 'avatars/elephant.webp',
      assetPath: 'assets/images/avatars/elephant.webp',
    ),
    RegistrationAvatar(
      label: 'Thỏ',
      color: Color(0xFFFFDDEB),
      storagePath: 'avatars/rabbit.webp',
      assetPath: 'assets/images/avatars/rabbit.webp',
    ),
    RegistrationAvatar(
      label: 'Gấu',
      color: Color(0xFFD9F7E8),
      storagePath: 'avatars/bear.webp',
      assetPath: 'assets/images/avatars/bear.webp',
    ),
    RegistrationAvatar(
      label: 'Cáo',
      color: Color(0xFFFFD7AE),
      storagePath: 'avatars/fox.webp',
      assetPath: 'assets/images/avatars/fox.webp',
    ),
  ];

  static List<RegistrationAvatar> get registrationAvatars {
    final client = supabaseClientOrNull;
    if (client == null) {
      return _avatarDefinitions;
    }

    return [
      for (final avatar in _avatarDefinitions)
        RegistrationAvatar(
          label: avatar.label,
          color: avatar.color,
          storagePath: avatar.storagePath,
          assetPath: avatar.assetPath,
          imageUrl: client.storage
              .from(SupabaseConfig.avatarBucket)
              .getPublicUrl(avatar.storagePath),
        ),
    ];
  }

  static RegistrationAvatar? findByStoragePath(String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) {
      return null;
    }

    for (final avatar in registrationAvatars) {
      if (avatar.storagePath == storagePath) {
        return avatar;
      }
    }
    return null;
  }
}
