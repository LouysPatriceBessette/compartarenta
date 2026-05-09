import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DbPaths {
  const DbPaths._();

  static const String dbDirName = 'compartarenta';
  static const String dbFileName = 'compartarenta.sqlite';

  static Future<Directory> dbDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, dbDirName));
  }

  static Future<File> dbFile() async {
    final dir = await dbDirectory();
    return File(p.join(dir.path, dbFileName));
  }
}

