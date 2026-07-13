// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'platform_storage.dart';

class WebStorage implements PlatformStorage {
  WebStorage(dynamic _);

  @override
  Future<bool> hasKey(String key) async {
    return html.window.localStorage.containsKey(key);
  }

  @override
  Future<String?> readString(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> writeString(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> deleteKey(String key) async {
    html.window.localStorage.remove(key);
  }
}

PlatformStorage getPlatformStorage(dynamic directory) => WebStorage(directory);
