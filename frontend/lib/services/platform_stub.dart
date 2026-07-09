// Stub for web - dart:io Platform not available
import 'package:flutter/foundation.dart';

class Platform {
  static bool get isAndroid => !kIsWeb;
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
}
