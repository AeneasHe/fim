import 'package:fim/service/preferences.dart';
import 'package:fim/model/message.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fim/dao/database_path.dart';

// 操作Message数据库: 连接 model 和 db
class MessageDao {
  static Database database;

  static init() async {
    // 数据库初始化
    database = await openDatabase(
      await databasePath('/message.db'),
      onCreate: (db, version) {
        print("创建数据库 message");
        return _onCreate(db, version);
      },
      version: 1,
    );
  }

  // 创建表
  static void _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE message (
            id INTEGER PRIMARY KEY,
            object_type INTEGER, 
            object_id INTEGER, 
            sender_id INTEGER,
            sender_nickname Text,
            sender_avatar_url Text,
            to_user_ids Text,
            message_type INTEGER,
            message_content BLOB,
            seq INTEGER,
            send_time INTEGER,
            status INTEGER
            )''',
    );

    await db.execute(
      '''
      CREATE UNIQUE INDEX object_seq ON message (object_type,object_id,seq)
      ''',
    );
  }

  // 添加消息
  static void add(Message message) async {
    try {
      await database.insert("message", message.toMap());
      setMaxSYN(message.seq);
    } catch (e) {
      print("保存新消息失败");
      print(e);
    }
  }

  // 更新消息的状态
  static void updateStatus(int objectType, int objectId, int status) async {
    await database.update(
      "message",
      {"status": status},
      where: "object_type = ? and object_id = ?",
      whereArgs: [objectType, objectId],
    );
  }

  // 列出消息
  static Future<List<Message>> list(
      int objectType, int objectId, int seq, int limit) async {
    List<Map> maps = await database.query(
      "message",
      where: "object_type = ? and object_id = ? and seq < ?",
      whereArgs: [objectType, objectId, seq],
      limit: limit,
      orderBy: "seq desc",
    );

    List<Message> messages = List<Message>();
    for (var map in maps) {
      messages.add(Message.fromMap(map));
    }
    return messages;
  }
}
