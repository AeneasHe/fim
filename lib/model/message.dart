import 'dart:typed_data';
import 'package:fim/pb/conn.ext.pb.dart' as pb;
import 'package:fim/pb/push.ext.pb.dart';
import 'package:fixnum/fixnum.dart';

// 消息数据结构
class Message {
  static const int objectTypeUser = 1; // 用户
  static const int objectTypeGroup = 2; // 群组
  static const int objectTypeSystem = 3; // 系统

  int objectType;
  int objectId;
  int senderId;
  String senderNickname;
  String senderAvatarUrl;
  String toUserIds;
  int messageType;
  Uint8List messageContent;
  int seq;
  int sendTime;
  int status;

  Message();

  // 解析消息：从pb.Message类型解析成 model.Message类型
  Message.fromPB(pb.Message message, Int64 userId) {
    var sender = message.sender; // 消息的发送者

    // 1.普通用户（好友）发送给自己的消息
    if (sender.senderType == pb.SenderType.ST_USER && // 如果发送者身份是普通用户
            sender.senderId != userId && // 如果不是自己发出来的消息
            message.receiverType == pb.ReceiverType.RT_USER // 如果消息是发给用户的
        ) {
      objectType = Message.objectTypeUser;
      objectId = sender.senderId.toInt();
      senderId = sender.senderId.toInt();
      senderNickname = sender.nickname;
      senderAvatarUrl = sender.avatarUrl;

      //toUserIds = message.toUserIds;  todo 初始化@
      messageType = message.messageType.value;
      messageContent = message.messageContent;
      seq = message.seq.toInt();
      sendTime = message.sendTime.toInt();
      status = message.status.value;
      return;
    }

    // 2.自己发送给普通用户（好友）的消息
    if (sender.senderType == pb.SenderType.ST_USER && //发送者是普通用户
            sender.senderId == userId && // 发送者的id是自己
            message.receiverType == pb.ReceiverType.RT_USER // 消息的接收者是普通用户
        ) {
      objectType = Message.objectTypeUser;
      objectId = message.receiverId.toInt();
      senderId = userId.toInt();
      senderNickname = sender.nickname;
      senderAvatarUrl = sender.avatarUrl;

      //toUserIds = message.toUserIds;  todo 初始化@
      messageType = message.messageType.value;
      messageContent = message.messageContent;
      seq = message.seq.toInt();
      sendTime = message.sendTime.toInt();
      status = message.status.value;
      return;
    }

    // 3.群组发送过来的消息
    if (message.receiverType == pb.ReceiverType.RT_SMALL_GROUP // 消息的接收者是群组
        ) {
      objectType = Message.objectTypeGroup;
      objectId = message.receiverId.toInt();
      senderId = sender.senderId.toInt();
      senderNickname = sender.nickname;
      senderAvatarUrl = sender.avatarUrl;

      //toUserIds = message.toUserIds;  todo 初始化@
      messageType = message.messageType.value;
      messageContent = message.messageContent;
      seq = message.seq.toInt();
      sendTime = message.sendTime.toInt();
      status = message.status.value;
      return;
    }

    // 4.系统消息
    if (sender.senderType == pb.SenderType.ST_SYSTEM // 消息的发送者是平台系统
        ) {
      var command = pb.Command.fromBuffer(message.messageContent);
      print(command);
      objectType = objectTypeSystem;
      objectId = command.code;
      messageType = message.messageType.value;
      messageContent = message.messageContent;
      seq = message.seq.toInt();
      sendTime = message.sendTime.toInt();
      status = message.status.value;
    }
  }

  // 解析命令，从pb.Command消息中，解析出命令
  String getCommandText() {
    String text = "";
    var command = pb.Command.fromBuffer(messageContent);

    // 修改了群组信息
    if (command.code == PushCode.PC_UPDATE_GROUP.value) {
      var push = UpdateGroupPush.fromBuffer(command.data);
      text = "${push.optName} 修改了群组信息";
    }

    // 群组邀请用户
    if (command.code == PushCode.PC_ADD_GROUP_MEMBERS.value) {
      var push = AddGroupMembersPush.fromBuffer(command.data);
      String names = "";
      for (var i = 0; i < push.members.length; i++) {
        if (i != push.members.length - 1) {
          names = names + push.members[i].nickname + "、";
        } else {
          names = names + push.members[i].nickname;
        }
      }
      text = "${push.optName} 邀请 $names 加入了群聊";
    }

    return text;
  }

  // 从map类型解析出 model.Message类型
  Message.fromMap(Map<String, dynamic> map) {
    objectType = map["object_type"];
    objectId = map["object_id"];
    senderId = map["sender_id"];
    senderNickname = map["sender_nickname"];
    senderAvatarUrl = map["sender_avatar_url"];
    toUserIds = map["to_user_ids"];
    messageType = map["message_type"];
    messageContent = map["message_content"];
    seq = map["seq"];
    sendTime = map["send_time"];
    status = map["status"];
  }

  // 从model.Message类型 转换成map类型
  Map<String, dynamic> toMap() {
    return {
      "object_type": objectType,
      "object_id": objectId,
      "sender_id": senderId,
      "sender_nickname": senderNickname,
      "sender_avatar_url": senderAvatarUrl,
      "to_user_ids": toUserIds,
      "message_type": messageType,
      "message_content": messageContent,
      "seq": seq,
      "send_time": sendTime,
      "status": status,
    };
  }
}
