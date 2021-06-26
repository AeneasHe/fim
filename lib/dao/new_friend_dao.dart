import 'package:fim/model/new_friend.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fim/dao/database_path.dart';

class NewFriendDao {
  static Database database;

  static Future<void> init() async {
    database = await openDatabase(
      await databasePath('/new_friend.db'),
      onCreate: (db, version) {
        print("创建数据库 new_friend");
        return _onCreate(db, version);
      },
      version: 1,
    );
  }

  // 创建表
  static void _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE new_friend (
            id INTEGER PRIMARY KEY,
            user_id INTEGER, 
            nickname Text, 
            avatar_url Text, 
            description Text,
            time INTEGER,
            status INTEGER
            )''',
    );

    await db.execute(
      '''
      CREATE UNIQUE INDEX object ON new_friend(user_id)
      ''',
    );
  }

  // 添加好友
  static void add(NewFriend friend) async {
    await database.insert("new_friend", friend.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 更新状态
  static void updateStatus(int userId, int status) async {
    await database.rawUpdate(
        "UPDATE new_friend SET status = ? where user_id = ?", [status, userId]);
  }

  // 读取
  static void read() async {
    await database.rawUpdate(
        "UPDATE new_friend SET status = ? where status = ?",
        [NewFriend.read, NewFriend.unread]);
  }

  // 列出好友
  static Future<List<NewFriend>> list() async {
    List<Map> maps = await database.query(
      "new_friend",
    );

    List<NewFriend> friends = List<NewFriend>();
    for (var map in maps) {
      friends.add(NewFriend.fromMap(map));
    }
    friends.sort((left, right) => right.time - left.time);
    return friends;
  }

  // 获取未读好友数量
  static Future<int> getUnreadNum() async {
    return Sqflite.firstIntValue(await database.rawQuery(
        "select count(*) from new_friend where status = ?",
        [NewFriend.unread]));
  }
}
