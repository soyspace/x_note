
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:XNote/controller/system_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/connect.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../service/onedrive_service.dart';
import '../storage/entity/notebook.dart';

const CLIENT_ID = 'f9d49aba-7540-4134-a378-1cc3de21b9b9';
const SCOPE = 'user.read mail.read Files.ReadWrite.All';
const REDIRECT_URI = 'http://localhost:53789/';
const GET_CODE =
    'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize?client_id=f9d49aba-7540-4134-a378-1cc3de21b9b9&response_type=code&redirect_uri=http://localhost:53789/&response_mode=query&scope=offline_access user.read mail.read Files.ReadWrite.All&state=12345';
const GET_TOKEN =
    'https://login.microsoftonline.com/consumers/oauth2/v2.0/token';
const GET_USERINFO = 'https://graph.microsoft.com/v1.0/me';
const GET_USERPHOTO = 'https://graph.microsoft.com/v1.0/me/photo/\$value';
const PREROOT = 'https://graph.microsoft.com/v1.0/me/drive/root';
const PREITEM = 'https://graph.microsoft.com/v1.0/me/drive/items';
const LOGOUT = 'https://login.live.com/logout.srf?ru=http://localhost:53789';

class OneDriverHttp extends GetConnect {
  static final OneDriverHttp instance = OneDriverHttp._();
  late Notebook _notebook;
  Map<String, dynamic>? _cloudConfig;

  Map<String, dynamic>? get cloudConfig {
    if (_cloudConfig == null &&  _notebook.cloudConfig!=null &&_notebook.cloudConfig!.isNotEmpty) {
      var tokenInfo=json.decode(_notebook.cloudConfig!)['tokenInfo'];
      _cloudConfig ??= tokenInfo is String? json.decode(tokenInfo):tokenInfo;
    }
    return _cloudConfig;
  }
  set cloudConfig (Map<String, dynamic>? value) {
    _cloudConfig = value;
  }
   set notebook (Notebook value) {
    _notebook = value;
    _cloudConfig = null;
  }
  OneDriverHttp._(){
    init();
  }
  void init() {
    httpClient.addRequestModifier<dynamic>((request) {
      if (cloudConfig != null) {
        request.headers['Authorization'] =
        '${cloudConfig?['token_type']} ${cloudConfig?['access_token']}';
      }
      return request;
    });
    httpClient.addResponseModifier<dynamic>((request, response) async {
      if (response.status.code! == 401 && response.hasError) {
        await OneDriveService.instance.requestTokenByRefreshToken(cloudConfig?['refresh_token'],);
        _cloudConfig = null;
        return await httpClient.send(request);
      }
      return response;
    });
  }

  Future<Map<String,dynamic>> getToken(String code) async {
    Response response = await post(GET_TOKEN, {
      'client_id': CLIENT_ID,
      'scope': SCOPE,
      'redirect_uri': REDIRECT_URI,
      'code': code,
      'grant_type': 'authorization_code',
    }, contentType: 'application/x-www-form-urlencoded');
    return response.body;
  }

  Future<Map> getTokenByRefreshToken(String refreshToken) async {
    Response response = await post(GET_TOKEN, {
      'client_id': CLIENT_ID,
      'scope': 'offline_access user.read mail.read Files.ReadWrite.All',
      'redirect_uri': REDIRECT_URI,
      'refresh_token': refreshToken,
      'grant_type': 'refresh_token',
    }, contentType: 'application/x-www-form-urlencoded');
    return response.body;
  }

  /// 获取文件信息
  /// {id:*,name:*}
  Future<Map> getItemInfo(String filePath) async {
    String url = '$PREROOT:$filePath';
    Response response = await get(url);
    return response.body;
  }

  /// 添加根目录下的子目录
  /// @param dirName
  /// response {id:*,name:*}
  Future<Map> addRootFolder(String dirName) async {
    String url = '$PREROOT/children';
    Response response = await post(url, {
      "name": dirName,
      "folder": {},
      "@microsoft.graph.conflictBehavior": "fail",
    });
    debugPrint('addRootFolder response->${response.body}');
    return response.body;
  }

  Future<Map> addFolder(String fileName, String parentId) async {
    String url = '$PREITEM/$parentId/children';
    Response response = await post(url, {
      "name": fileName,
      "folder": {},
      "@microsoft.graph.conflictBehavior": "fail",
    });
    debugPrint('addFolder->$url');
    return response.body;
  }

  /// 添加文件
  Future<Map> addFile(String fileName, String content, String parentId) async {
    String url = '$PREITEM/$parentId:/$fileName:/content';
    return await uploadAttachment(url, utf8.encode(content));
  }

  /// 添加文件
  /// 添加文件
  Future<Map> addFileByPath(
      String fileName,
      String content,
      String path,
      ) async {

    String url = '$PREROOT:$path/$fileName:/content';
    return await uploadAttachment(url, utf8.encode(content));
  }
  Future<void> addAttachment(String fileName,String path)async{
    String url = '$PREROOT:$path/$fileName:/content';
    File file = File(p.join(SystemController.to.system!.cacheDir!,'files',fileName));
    if(!file.existsSync()) return;
    await uploadAttachment(url, file.readAsBytesSync());
  }
  Future<Map> uploadAttachment(String url,List<int> bytes)async{
    final uri = Uri.parse(url!);
    Request request = Request(
        method: 'put',
        url: uri,
        headers: {'Authorization':'${cloudConfig?['token_type']} ${cloudConfig?['access_token']}',
          'content-type':'multipart/form-data'},
        bodyBytes: _trackProgress(bytes,null),
        contentLength: bytes?.length ?? 0,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects);
    Response response = await httpClient.send(request);
    debugPrint('addAttachment $url 》 ${response.body==null?response.toString():""}');
    return response.body;
  }
  Future<void> downloadAttachment(String fileName,String path)async{
    File file = File(p.join(SystemController.to.system!.cacheDir!,'files',fileName));
    if(file.existsSync()) return;

    String url = '$PREROOT:$path/$fileName:/content';
    Response response = await httpClient.get(url,
        responseInterceptor: (request,targetType,response) async{
          List<List<int>> list =await response.toList();
          List<int> ll =[];
          for(List<int> l in list){
            ll.addAll(l);
          }
          return Response(
            statusCode: 200,
            body: ll,
          );
        });
    debugPrint('downloadAttachment $fileName');
    if(response.statusCode==200){
      file.createSync(recursive: true);
      await file.writeAsBytes(response.body);
    }
    return response.body;
  }

  Stream<List<int>> _trackProgress(
      List<int> bodyBytes,
      Progress? uploadProgress,
      ) {
    var total = 0;
    var length = bodyBytes.length;

    var byteStream =
    Stream.fromIterable(bodyBytes.map((i) => [i])).transform<List<int>>(
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        total += data.length;
        if (uploadProgress != null) {
          var percent = total / length * 100;
          uploadProgress(percent);
        }
        sink.add(data);
      }),
    );
    return byteStream;
  }
  ///
  /// response [{id:*,name:*},{id:*,name:*}]
  /// response [{id:*,name:*},{id:*,name:*}]
  Future<List<Map>> listItemsInfo(String id, {String? url_}) async {
    String url = url_ == null ? '$PREITEM/$id/children' : '$url_/$id/children';
    Response response = await get(url);
    if (response.body['@odata.nextLink'] != null) {
      List<Map> list = await listItemsInfo(
        id,
        url_: response.body['@odata.nextLink'],
      );
      // 安全地将 dynamic 元素转换为 Map
      List<Map> currentValue =
      (response.body['value'] as List).map((item) => item as Map).toList();
      currentValue.addAll(list);
      return currentValue;
    }
    // 安全地将 dynamic 元素转换为 Map
    return (response.body['value'] as List).map((item) => item as Map).toList();
  }

  /// 获取文件内容
  Future<String> getItemContent(String fileName, String path) async {
    String url = '$PREROOT:$path/$fileName:/content';
    Response response = await get(url);
    debugPrint('getItemContent $fileName');
    //return response.body is String ? subItemContent(response.body) : "null";
    if(response.statusCode==404) return 'null';
    return  response.body;
  }

  String subItemContent(String body) {
    return body.substring(body.indexOf('{'), body.lastIndexOf('}') + 1);
  }

  /// 删除文件
  Future<Map> deleteItem(String id) async {
    String url = '$PREITEM/$id';
    Response response = await delete(url);
    return response.body;
  }

  /// 获取用户信息
  Future<Map> getUserInfo() async {
    String url = GET_USERINFO;
    Response response = await get(url);
    return response.body;
  }

  /// 获取用户头像
  Future<List<int>> getUserAvatar() async {
    String url = GET_USERPHOTO;
    Response response = await httpClient.get(url,
        responseInterceptor: (request,targetType,response) async{
            List<List<int>> list =await response.toList();
            List<int> ll =[];
            for(List<int> l in list){
              ll.addAll(l);
            }
            return Response(
              statusCode: 200,
              body: ll,
            );
        });
    return response.body;
  }
  /// 登出
  Future<void> logout() async {
    await launchUrl(Uri.parse(LOGOUT));
  }
}