import 'package:fim/pb/business.ext.pbgrpc.dart';
import 'package:fim/pb/logic.ext.pbgrpc.dart';
import 'package:grpc/grpc.dart';

const String baseUrl = "172.20.10.3";
const String uploadUrl = "http://172.20.10.3:8085/upload";

final logicClient = LogicExtClient(ClientChannel(
  baseUrl,
  port: 50001,
  options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
));

final businessClient = BusinessExtClient(ClientChannel(
  baseUrl,
  port: 50301,
  options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
));
