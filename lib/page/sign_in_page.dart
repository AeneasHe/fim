import 'dart:ffi';
import 'package:fim/pb/business.ext.pb.dart';
import 'package:fim/service/preferences.dart';
import 'package:fim/page/init_page.dart';
import 'package:fim/page/set_user_page.dart';
import 'package:fim/net/api.dart';
import 'package:fim/theme/color.dart';
import 'package:fim/theme/size.dart';
import 'package:fim/util/toast.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 登陆页面
class SignInPage extends StatelessWidget {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text("登录"),
        brightness: appBarBrightness,
      ),
      body: Container(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
        color: Colors.white,
        alignment: Alignment.topCenter,
        //height: 500,
        child: Column(
          children: <Widget>[
            TextField(
              autofocus: true,
              maxLines: 1,
              style: TextStyle(
                fontSize: 20,
              ),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "手机号",
                prefixIcon: Icon(Icons.phone_android),
              ),
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(11) //限制长度
              ],
              controller: _numberController,
            ),
            TextField(
              style: TextStyle(
                fontSize: 20,
              ),
              maxLines: 1,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(6) //限制长度
              ],
              decoration: InputDecoration(
                labelText: "验证码",
                prefixIcon: Icon(Icons.menu),
              ),
              controller: _codeController,
            ),
            Container(
              height: 30,
            ),
            SizedBox(
              height: 40,
              width: 300,
              child: FlatButton(
                color: Colors.green,
                child: Text("登录"),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0)),
                onPressed: () {
                  signIn(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void signIn(BuildContext context) async {
    var number = _numberController.text;
    var code = _codeController.text;
    //number = "18800001111";
    //
    if (number.length != 11) {
      Fluttertoast.showToast(
          msg: "请输入11位的手机号",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Colors.black45,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    code = "123456";
    // if (code.length != 6) {
    //   Fluttertoast.showToast(
    //       msg: "请输入6位的验证码",
    //       toastLength: Toast.LENGTH_SHORT,
    //       gravity: ToastGravity.CENTER,
    //       timeInSecForIos: 1,
    //       backgroundColor: Colors.black45,
    //       textColor: Colors.white,
    //       fontSize: 16.0);
    //   return;
    // }

    // 创建登录请求
    var request = SignInReq();
    request.phoneNumber = number;
    request.code = code;

    // 从存储获取设备id
    var prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getInt(deviceIdKey);

    deviceId = 1;
    print("sign_in_page device_id:$deviceId");

    request.deviceId = Int64(deviceId);

    SignInResp signInResp;
    // 执行登录请求
    try {
      signInResp = await businessClient.signIn(request);
      print("登录结果:" + signInResp.toString());
    } catch (e) {
      print(e);
      toast("登录失败");
      return;
    }

    // 将数据保存到数据库
    // 主要是：userId 和 token
    await prefs.setInt(userIdKey, signInResp.userId.toInt());
    await prefs.setString(tokenKey, signInResp.token);
    await sharedPreferences.setString(phoneNumberKey, number);

    // 请求获取用户的profile信息
    var getUserResp =
        await businessClient.getUser(GetUserReq(), options: getOptions());
    await sharedPreferences.setString(nicknameKey, getUserResp.user.nickname);
    await sharedPreferences.setString(avatarUrlKey, getUserResp.user.avatarUrl);

    if (signInResp.isNew) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SetUserPage(true)));
      return;
    }

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => InitPage()));
  }
}
