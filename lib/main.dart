import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:fim/theme/color.dart';
// 服务
import 'package:fim/service/chat_service.dart';
import 'package:fim/service/friend_service.dart';
import 'package:fim/service/new_friend_service.dart';
import 'package:fim/service/recent_contact_service.dart';
// 页面
import 'package:fim/page/chat/chat_page.dart';
import 'package:fim/page/init_page.dart';

void main() {
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: backgroundColor,
    ));
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => recentContactService),
        ChangeNotifierProvider(create: (_) => friendService),
        ChangeNotifierProvider(create: (_) => newFriendService),
        ChangeNotifierProvider(create: (_) => chatService),
      ],
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        backgroundColor: backgroundColor,
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          color: backgroundColor,
          textTheme: TextTheme(
            headline6: TextStyle(color: Colors.black, fontSize: 17),
          ),
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
        ),
      ),
      home: (InitPage()), // 初始页面
      routes: {
        '/chatPage': (context) => ChatPage(),
      },
    );
  }
}
