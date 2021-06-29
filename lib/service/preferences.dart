import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const deviceIdKey = "device_id";
const userIdKey = "user_id";
const tokenKey = "token";
const nicknameKey = "nickname";
const avatarUrlKey = "avatar_url";
const phoneNumberKey = "phone_number";

const maxSYNKey = "max_syn";

SharedPreferences sharedPreferences;
// 用户偏好设置

// 查询选项
CallOptions getOptions() {
  var metadata = {
    "device_id": sharedPreferences.getInt(deviceIdKey).toString(),
    "user_id": sharedPreferences.getInt(userIdKey).toString(),
    "token": sharedPreferences.getString(tokenKey)
  };
  return CallOptions(metadata: metadata);
}

// 查询设备id
Int64 getDeviceId() {
  return Int64(sharedPreferences.getInt(deviceIdKey));
}

// 查询用户id
Int64 getUserId() {
  return Int64(sharedPreferences.getInt(userIdKey));
}

// 查询tokne
String getToken() {
  return sharedPreferences.getString(tokenKey);
}

// 查询昵称
String getNickname() {
  return sharedPreferences.getString(nicknameKey);
}

// 查询头像链接
String getAvatarUrl() {
  return sharedPreferences.getString(avatarUrlKey);
}

// 查询电话号码
String getPhoneNumber() {
  return sharedPreferences.getString(phoneNumberKey);
}

Future<void> setMaxSYN(int maxSYN) async {
  return sharedPreferences.setInt("${getUserId()}_$maxSYNKey", maxSYN);
}

Int64 getMaxSYN() {
  return Int64(sharedPreferences.getInt("${getUserId()}_$maxSYNKey") ?? 0);
}
