import 'package:fim/dao/new_friend_dao.dart';
import 'package:fim/model/new_friend.dart';
import 'package:flutter/cupertino.dart';

var newFriendService = NewFriendService();

// 新的朋友服务
class NewFriendService with ChangeNotifier {
  int unreadNum = 0; // 没有阅读的新好友数量
  List<NewFriend> list;

  initUnread() async {
    print("initUnread");
    unreadNum = await NewFriendDao.getUnreadNum(); // 本地数据库查询未阅读的新好友数量
  }

  initNewFriendList() async {
    list = await NewFriendDao.list();
  }

  // 添加好友
  void add(NewFriend friend) {
    NewFriendDao.add(friend); // 将新好友添加到本地数据库
    unreadNum++;
    if (list != null) {
      list.insert(0, friend);
    }
    notifyListeners();
  }

  // 读取好友
  void read() async {
    NewFriendDao.read();
    unreadNum = 0;
    notifyListeners();
  }

  // 更新状态
  void updateStatus(int userId, int status) {
    NewFriendDao.updateStatus(userId, status);
    for (var item in list) {
      if (item.userId == userId) {
        item.status = status;
      }
    }
    notifyListeners();
  }
}
