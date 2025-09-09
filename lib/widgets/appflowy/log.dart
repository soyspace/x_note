// ignore: import_of_legacy_library_into_null_safe





import 'package:flutter/widgets.dart';

class Log {

static void _log(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
     debugPrint('Log: $msg');
  }
  static void info(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    // This method is intentionally left empty.
    // It can be used for informational logging if needed.
    _log(  msg, error, stackTrace);
  }

  static void debug(dynamic msg, [dynamic error, StackTrace? stackTrace]) {

  }

  static void warn(dynamic msg, [dynamic error, StackTrace? stackTrace]) {

  }

  static void trace(dynamic msg, [dynamic error, StackTrace? stackTrace]) {

  }

  static void error(dynamic msg, [dynamic error, StackTrace? stackTrace]) {

  }
}
