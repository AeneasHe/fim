import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:fim/dao/recent_contact_dao.dart';
import 'package:fim/service/chat_service.dart';
import 'package:fim/service/friend_service.dart';
import 'package:fim/service/groups.dart';
import 'package:fim/service/new_friend_service.dart';
import 'package:fim/service/preferences.dart';
import 'package:fim/service/recent_contact_service.dart';
import 'package:fim/model/new_friend.dart';
import 'package:fim/model/recent_contact.dart';
import 'package:fim/notification/notification.dart';
import 'package:fim/pb/conn.ext.pb.dart' as pb;
import 'package:fim/model/message.dart' as model;
import 'package:fim/pb/push.ext.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

// Socket长连接
class SocketManager {
  static const headerLen = 2;
  static Socket socket;
  static List<int> readBuffer = List<int>();

  Future<void> connect(String host, int port) async {
    // tcp长连接
    await Socket.connect(host, port, timeout: Duration(seconds: 2)).then((s) {
      print("长连接成功");
      socket = s;
      socket.listen(onData,
          onError: onError, onDone: doneHandler, cancelOnError: true);
    });

    // 长连接登录
    var input = pb.SignInInput();
    input.deviceId = getDeviceId();
    input.userId = getUserId();
    input.token = getToken();

    var buffer = encode(pb.PackageType.PT_SIGN_IN, input);
    socket.add(buffer);
    await socket.flush();
    print("长连接登录");

    // 长连接心跳
    Future.delayed(Duration(seconds: 5), () {
      socket.add(encode(pb.PackageType.PT_HEARTBEAT, null));
      socket.flush();
    });
  }

  void onData(Uint8List list) {
    print("长连接收到数据");

    readBuffer.addAll(list);

    if (readBuffer.length < headerLen) {
      return;
    }

    int header1 = readBuffer[0];
    int header2 = readBuffer[1];
    readBuffer.removeRange(0, headerLen);
    int bodyLength = header1 * 256 + header2;

    var body = readBuffer.getRange(0, bodyLength).toList();
    readBuffer.removeRange(0, bodyLength);

    // 解析数据
    var output = pb.Output.fromBuffer(body);
    print("收到消息:" + output.toString());

    // 根据收到的数据执行不同操作
    switch (output.type) {
      // 登录成功时
      case pb.PackageType.PT_SIGN_IN:
        if (output.code != 0) {
          print("signIn error code:${output.code};message:${output.message}");
          return;
        }
        print("长连接登录成功");

        // 触发消息同步
        var input = pb.SyncInput();
        input.seq = getMaxSYN();
        print("触发消息同步，seq:${input.seq}");
        socket.add(encode(pb.PackageType.PT_SYNC, input));
        socket.flush();

        // 触发定时心跳
        Timer.periodic(Duration(minutes: 4, seconds: 30), (timer) {
          print("heartbeat input");
          socket.add(encode(pb.PackageType.PT_HEARTBEAT, null));
          socket.flush();
        });
        break;

      // 收到同步消息
      case pb.PackageType.PT_SYNC:
        print("长连接收到同步消息sync1");
        var syncOutput = pb.SyncOutput.fromBuffer(output.data);
        if (syncOutput.messages.length <= 0) {
          return;
        }
        print("长连接收到同步消息sync2");
        var maxSYN = syncOutput.messages.last.seq;
        messageACK(output.requestId, maxSYN);

        for (var message in syncOutput.messages) {
          print("长连接收到同步消息sync3");

          try {
            handleMessage(message);
          } catch (e) {
            print(e);
            print("处理消息失败" + message.toString());
          }
        }
        if (syncOutput.hasMore == true) {
          print("长连接收到同步消息sync4");
          var input = pb.SyncInput();
          input.seq = syncOutput.messages.last.seq;
          socket.add(encode(pb.PackageType.PT_SYNC, input));
          socket.flush();
        }
        break;
      // 心跳
      case pb.PackageType.PT_HEARTBEAT:
        print("heartbeat output");
        break;

      // 普通消息
      case pb.PackageType.PT_MESSAGE:
        print("message");
        var messageSend = pb.MessageSend.fromBuffer(output.data);
        messageACK(output.requestId, messageSend.message.seq);

        handleMessage(messageSend.message);
        break;
    }
  }

  void onError(error, StackTrace trace) {
    socket.close();
    print("捕获socket异常信息：error=$error，trace=${trace.toString()}");
  }

  // 长连接关闭
  void doneHandler() {
    socket.destroy();
    print("socket关闭处理");
  }

  Uint8List encode(pb.PackageType type, GeneratedMessage message,
      [Int64 requestId]) {
    // 构建输入流
    var input = pb.Input();
    input.type = type;
    if (requestId == null) {
      input.requestId = Int64(DateTime.now().microsecondsSinceEpoch);
    }
    if (message != null) {
      input.data = message.writeToBuffer();
    }

    var buffer = input.writeToBuffer();
    var length = buffer.length;

    var writeBuffer = List<int>();

    writeBuffer.add(length ~/ 256);
    writeBuffer.add(length % 256);
    writeBuffer.addAll(buffer);

    return Uint8List.fromList(writeBuffer);
  }

  void messageACK(Int64 requestId, Int64 seq) {
    var ack = pb.MessageACK();
    ack.deviceAck = seq;
    ack.receiveTime = Int64(DateTime.now().millisecondsSinceEpoch);
    socket.add(encode(pb.PackageType.PT_MESSAGE, ack, requestId));
  }

  handleMessage(pb.Message msg) async {
    print("handleMessage");
    var message = model.Message.fromPB(msg, getUserId());
    print(message.toMap());

    // 好友消息
    if (message.objectType == model.Message.objectTypeUser) {
      print("====>处理好友消息");
      // 处理消息逻辑
      chatService.onMessage(message);

      // 保存到最近联系人
      try {
        var contact = await RecentContact.build(message);
        recentContactService.onMessage(contact);
        if (!chatService.isOpen(contact.objectType, contact.objectId)) {
          showNotifications(contact.name, contact.lastMessage);
        }
      } catch (e) {
        print(e);
        print("保存消息到最近联系人失败");
      }

      return;
    }

    // 群组消息
    if (message.objectType == model.Message.objectTypeGroup) {
      print("====>处理群组消息");

      // 处理消息逻辑
      chatService.onMessage(message);

      try {
        // 保存到最近联系人
        var contact = await RecentContact.build(message);
        recentContactService.onMessage(contact);

        if (!chatService.isOpen(contact.objectType, contact.objectId)) {
          showNotifications(contact.name, contact.lastMessage);
        }
      } catch (e) {
        print(e);
        print("保存到最近联系人失败");
      }

      // 处理群组系统消息
      if (msg.sender.senderType == pb.SenderType.ST_SYSTEM) {
        if (message.messageType != pb.MessageType.MT_COMMAND.value) return;
        var command = pb.Command.fromBuffer(message.messageContent);
        print("command from net ${command.code}");
        // 处理群组信息变更
        if (command.code == PushCode.PC_UPDATE_GROUP.value) {
          var updateGroupPush = UpdateGroupPush.fromBuffer(command.data);
          print("command from net $updateGroupPush");
          await RecentContactDao.updateInfo(
            model.Message.objectTypeGroup,
            message.objectId,
            updateGroupPush.name,
            updateGroupPush.avatarUrl,
          );

          friendService.changed();

          var group = await Groups.get(Int64(message.objectId));
          group.name = updateGroupPush.name;
          group.avatarUrl = updateGroupPush.avatarUrl;
        }
      }
      return;
    }

    // 系统消息
    if (message.objectType == model.Message.objectTypeSystem) {
      print("=====>处理系统消息");

      var command = pb.Command.fromBuffer(message.messageContent);

      // 添加好友
      if (message.objectId == PushCode.PC_ADD_FRIEND.value) {
        var addFriendPush = AddFriendPush.fromBuffer(command.data);
        print("添加好友:$addFriendPush");
        var newFriend = NewFriend(
          userId: addFriendPush.friendId.toInt(),
          nickname: addFriendPush.nickname,
          avatarUrl: addFriendPush.avatarUrl,
          description: addFriendPush.description,
          time: message.sendTime,
          status: NewFriend.unread,
        );
        newFriendService.add(newFriend);
        return;
      }
      // 同意添加好友
      if (message.objectId == PushCode.PC_AGREE_ADD_FRIEND.value) {
        // 重新加载好友列表
        await friendService.init();
        var contact = RecentContact();
        contact.objectType = model.Message.objectTypeUser;
        var agreeAddFriendPush = AgreeAddFriendPush.fromBuffer(command.data);

        contact.objectId = agreeAddFriendPush.friendId.toInt();
        contact.name = agreeAddFriendPush.nickname;
        contact.avatarUrl = agreeAddFriendPush.avatarUrl;
        contact.lastMessage = "成功添加好友";
        contact.lastTime = Int64(DateTime.now().millisecondsSinceEpoch).toInt();
        contact.unread = 0;
        recentContactService.onMessage(contact);
        return;
      }
    }
  }
}
