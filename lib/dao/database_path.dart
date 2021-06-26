import 'package:sqflite/sqflite.dart';
import 'package:fim/service/preferences.dart';
import 'package:path/path.dart';

// 获取本地sqlite数据库文件路径
databasePath(String filename) async {
  var path = join(await getDatabasesPath(), getUserId().toString() + filename);
  print("database path:" + path);
  return path;
}
