import 'platform_storage_stub.dart'
    if (dart.library.io) 'platform_storage_io.dart'
    if (dart.library.html) 'platform_storage_web.dart';

abstract class PlatformStorage {
  Future<bool> hasKey(String key);
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> deleteKey(String key);
}

PlatformStorage createPlatformStorage(dynamic directory) =>
    getPlatformStorage(directory);
