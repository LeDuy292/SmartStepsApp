import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'platform_storage.dart';

class IoStorage implements PlatformStorage {
  IoStorage(this.directoryOverride);

  final Directory? directoryOverride;

  Future<Directory> _directory() async {
    if (directoryOverride != null) return directoryOverride!;
    final docsDir = await getApplicationDocumentsDirectory();
    return Directory('${docsDir.path}${Platform.pathSeparator}SmartSteps');
  }

  Future<File> _file(String key) async {
    final dir = await _directory();
    return File('${dir.path}${Platform.pathSeparator}$key.json');
  }

  @override
  Future<bool> hasKey(String key) async {
    final file = await _file(key);
    return file.exists();
  }

  @override
  Future<String?> readString(String key) async {
    final file = await _file(key);
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }

  @override
  Future<void> writeString(String key, String value) async {
    final file = await _file(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<void> deleteKey(String key) async {
    final file = await _file(key);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

PlatformStorage getPlatformStorage(dynamic directory) =>
    IoStorage(directory as Directory?);
