import 'package:fim/dao/message_dao.dart';
import 'package:fim/pb/conn.ext.pb.dart' as pb;
import 'package:fim/pb/conn.ext.pbenum.dart';
import 'package:fim/pb/push.ext.pb.dart';
import 'package:fim/pb/push.ext.pbenum.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fim/model/message.dart';
import 'package:flutter/cupertino.dart';

class ChatData {
  String name;
  List<Message> messages;

  ChatData(this.name, this.messages);
}

var chatService = ChatService();

// 聊天服务
class ChatService with ChangeNotifier {
  Map<String, ChatData> map = Map();

  String key(int objectType, int objectId) {
    return "$objectType-$objectId";
  }

  // 初始化
  init(int objectType, int objectId, String name) async {
    // 从数据库取出消息，最多20条
    var messages = await MessageDao.list(
        objectType, objectId, Int64.MAX_VALUE.toInt(), 20);
    map[key(objectType, objectId)] = ChatData(name, messages);
  }

  // 清空消息
  destroy(int objectType, int objectId) {
    map.remove(key(objectType, objectId));
  }

  bool isOpen(int objectType, int objectId) {
    var chatData = map[key(objectType, objectId)];
    if (chatData == null) {
      return false;
    }
    return true;
  }

  // 获取聊天数据
  ChatData getChatData(int objectType, int objectId) {
    return map[key(objectType, objectId)];
  }

  // 发送聊天数据
  void sendMessage(Message event) async {
    var chatData = map[key(event.objectType, event.objectId)];
    if (chatData == null) return;

    if (event.messageType == MessageType.MT_TEXT.value ||
        event.messageType == MessageType.MT_IMAGE.value) {
      chatData.messages.insert(0, event);
      notifyListeners();
    }
  }

  // 保存聊天记录
  void save(Message event) async {
    await MessageDao.add(event);
  }

  // 新消息
  void onMessage(Message event) async {
    await MessageDao.add(event);

    var chatData = map[key(event.objectType, event.objectId)];
    if (chatData == null) return;

    if (event.messageType == MessageType.MT_TEXT.value ||
        event.messageType == MessageType.MT_IMAGE.value) {
      chatData.messages.insert(0, event);
      notifyListeners();
    }

    // 指令消息
    if (event.messageType == MessageType.MT_COMMAND.value) {
      var command = pb.Command.fromBuffer(event.messageContent);
      print("指令消息：${command.code}");
      // 群组信息更新
      if (command.code == PushCode.PC_UPDATE_GROUP.value) {
        var updateGroupPush = UpdateGroupPush.fromBuffer(command.data);
        chatData.name = updateGroupPush.name;
        chatData.messages.insert(0, event);
        notifyListeners();
      }
      if (command.code == PushCode.PC_ADD_GROUP_MEMBERS.value) {
        chatData.messages.insert(0, event);
        notifyListeners();
      }
    }
  }

  // 加载更多消息
  void loadMore(int objectType, int objectId) async {
    var chatData = map[key(objectType, objectId)];
    var messages = chatData.messages;
    var moreMessage =
        await MessageDao.list(objectType, objectId, messages.last.seq, 20);
    messages.addAll(moreMessage);
    notifyListeners();
  }

  // 名字发生变化时
  void onChangeName(int objectType, int objectId, String name) {
    var chatData = map[key(objectType, objectId)];
    if (chatData == null) return;

    chatData.name = name;
    notifyListeners();
  }
}
