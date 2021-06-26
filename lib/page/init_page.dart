// import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// dao
import 'package:fim/dao/message_dao.dart';
import 'package:fim/dao/new_friend_dao.dart';
import 'package:fim/dao/recent_contact_dao.dart';

// 服务
import 'package:fim/service/friend_service.dart';
import 'package:fim/service/new_friend_service.dart';
import 'package:fim/service/preferences.dart';
import 'package:fim/service/recent_contact_service.dart';

// 工具
import 'package:fim/notification/notification.dart';
import 'package:fim/pb/logic.ext.pb.dart';
import 'package:fim/net/api.dart';
import 'package:fim/net/socket_manager.dart';

// 页面
import 'package:fim/page/sign_in_page.dart';
import 'home/home_page.dart';

// 初始化页面，每次启动app时进入本页面
class InitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 初始化数据
    initData(context);

    return Scaffold(
      body: Container(
        child: Center(
          child: Text(
            "FIM",
            style: TextStyle(fontSize: 30, color: Colors.green),
          ),
        ),
      ),
    );
  }

  void initData(BuildContext context) async {
    // 初始化通知栏
    initNotification();

    sharedPreferences = await SharedPreferences.getInstance();

    // 检查设备id
    var deviceId = sharedPreferences.getInt(deviceIdKey);
    print("init_page_device_id:$deviceId");

    // deviceId = 1;
    // await sharedPreferences.setInt(deviceIdKey, deviceId);

    if (deviceId == null) {
      // 如果设备号为空，则注册设备
      //var deviceInfo = DeviceInfoPlugin();
      //var androidInfo = await deviceInfo.androidInfo;

      // 注册社保请求
      var request = RegisterDeviceReq();
      request.type = 2; // 这里1表示Android，2表示ios
      request.brand = "apple"; //androidInfo.brand;手机品牌
      request.model = "iphone12"; //androidInfo.product; 手机型号
      request.systemVersion = "ios13"; // androidInfo.version.release;系统号
      request.sdkVersion = "1.0.0";

      // 发送注册设备的请求
      var response = await logicClient.registerDevice(request);
      var newDeviceId = response.deviceId.toInt();
      await sharedPreferences.setInt(deviceIdKey, newDeviceId);
      print("init_page set devoce_id = $newDeviceId");
    }

    // 检查本地数据库中是否有已经的登录信息
    var userId = sharedPreferences.getInt(userIdKey);
    var token = sharedPreferences.getString(tokenKey);

    // 如果userId为空，token为空，则需要退出重新登录
    if (userId == null || token == null) {
      print("用户尚未登录,跳转至登录页面");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SignInPage()));
      return;
    }

    // 初始化数据库连接

    // 初始化最近联系人
    await RecentContactDao.init();
    // 初始化消息
    await MessageDao.init();
    // 初始化新好友
    await NewFriendDao.init();

    // 初始化最近联系人
    context.read<RecentContactService>().init();

    // 以下需要网络连接

    // 初始化好友信息
    await friendService.init();

    // 初始化新好友好友
    await newFriendService.initUnread();

    // 长连接登录:TCP 8088端口
    await SocketManager().connect(baseUrl, 8088);

    print("跳转至主页");
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }
}
