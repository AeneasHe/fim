import 'package:fim/pb/business.ext.pbgrpc.dart';
import 'package:fim/pb/logic.ext.pbgrpc.dart';
import 'package:grpc/grpc.dart';

const String baseUrl = "127.0.0.1";
const String uploadUrl = "http://127.0.0.1:8085/upload";

// 逻辑客户端
final logicClient = LogicExtClient(ClientChannel(
  baseUrl,
  port: 50001,
  options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
));

// 业务客户端
final businessClient = BusinessExtClient(ClientChannel(
  baseUrl,
  port: 50301,
  options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
));
