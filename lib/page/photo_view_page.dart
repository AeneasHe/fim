import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

// 查看照片页面
class PhotoViewPage extends StatelessWidget {
  final String url;

  PhotoViewPage(this.url);

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (url.startsWith("/")) {
      imageProvider = AssetImage(url);
    } else {
      imageProvider = NetworkImage(url);
    }

    return Scaffold(body: PhotoView(imageProvider: imageProvider));
  }
}
