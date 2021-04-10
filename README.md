# fim

一个基于 gim 服务端的移动客户端，使用 flutter 编写

## 协议编译命令

cd lib/proto
protoc --dart_out=grpc:../pb/ \*ext.proto

## 服务器地址

修改文件 lib/net/api.dart

```
const String baseUrl = "47.242.224.6";
const String uploadUrl = "http://47.242.224.6:8085/upload";

```