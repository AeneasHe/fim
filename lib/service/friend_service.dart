import 'package:fim/service/preferences.dart';
import 'package:fim/net/api.dart';
import 'package:fim/pb/logic.ext.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';

var friendService = FriendService();

// 好友微服务
class FriendService with ChangeNotifier {
  List<Friend> friendList;
  Map<Int64, Friend> friendMap;

  // 初始化
  init() async {
    print("friendService init");

    // 先查询所有好友
    var response =
        await logicClient.getFriends(GetFriendsReq(), options: getOptions());

    // 好友列表
    friendList = response.friends;

    // 好友Map
    friendMap = Map();
    for (var friend in friendList) {
      print("我的好友:" + friend.toString());
      friendMap[friend.userId] = friend;
    }
  }

  // 查询好友
  Friend get(Int64 friendId) {
    return friendMap[friendId];
  }

  // 好友发生变化时，发出通知
  void changed() {
    notifyListeners();
  }
}
