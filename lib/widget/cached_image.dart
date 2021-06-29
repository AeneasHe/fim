//import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  String imageUrl;
  int width;
  int height;
  BoxFit fit;

  CachedImage(
      {String imageUrl,
      int width = 50,
      int height = 50,
      BoxFit fit = BoxFit.fill}) {
    this.imageUrl = imageUrl;
    this.width = width;
    this.height = height;
    this.fit = fit;
  }
  @override
  Widget build(BuildContext context) {
    //print("imageUrl" + imageUrl.toString());
    var w = Image.asset("assets/avatar.jpeg");
    if (["user1.jpeg", "user2.jpeg", "user3.jpeg", "user4.jpeg", "user5.jpeg"]
        .contains(imageUrl)) {
      print("头像:" + imageUrl);
      w = Image.asset("assets/" + imageUrl);
    }
    return w;
    // if (imageUrl != null) {
    //   return CachedNetworkImage(imageUrl: imageUrl);
    // } else {
    //   return Text("no avatar");
    // }
  }
}
