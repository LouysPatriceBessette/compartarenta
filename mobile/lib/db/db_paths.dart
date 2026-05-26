import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DbPaths {
  const DbPaths._();

  static const String dbDirName = 'compartarenta';
  static const String dbFileName = 'compartarenta.sqlite';

  static Future<Directory> dbDirectory() async {
    final docs = await _getApplicationDocumentsDirectoryWithRetry();
    return Directory(p.join(docs.path, dbDirName));
  }

  static Future<File> dbFile() async {
    final dir = await dbDirectory();
    return File(p.join(dir.path, dbFileName));
  }

  static Future<Directory> _getApplicationDocumentsDirectoryWithRetry() async {
    const delays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 120),
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
    ];
    Object? lastError;
    StackTrace? lastStack;
    for (var i = 0; i < delays.length; i++) {
      if (delays[i] > Duration.zero) {
        await Future<void>.delayed(delays[i]);
      }
      try {
        return await getApplicationDocumentsDirectory();
      } on MissingPluginException catch (e, st) {
        lastError = e;
        lastStack = st;
      }
    }
    Error.throwWithStackTrace(
      lastError ??
          MissingPluginException(
            'path_provider plugin was unavailable after retries',
          ),
      lastStack ?? StackTrace.current,
    );
  }
}
