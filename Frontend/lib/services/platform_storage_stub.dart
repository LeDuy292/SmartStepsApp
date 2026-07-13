import 'platform_storage.dart';

PlatformStorage getPlatformStorage(dynamic directory) {
  throw UnsupportedError('Cannot create platform storage without platform implementation.');
}
