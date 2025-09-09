import 'dart:convert';
import 'dart:io';

import 'package:XNote/controller/diary_controller.dart';
import 'package:XNote/controller/document_controller.dart';
import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/controller/remote_controller.dart';
import 'package:XNote/controller/system_controller.dart';
import 'package:XNote/pages/left/tree_node.dart';
import 'package:XNote/storage/entity/notebook.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:url_launcher/url_launcher.dart';

import '../storage/entity/note.dart';
import '../utils/note_utils.dart';
import '../utils/one_drive_connect.dart';


class OneDriveService {

  static OneDriveService instance = OneDriveService._();
  OneDriveService._();

  HttpServer? httpServer;
  Notebook? _notebook;
  Notebook? get notebook => _notebook;
  set notebook(Notebook? notebook_) {
    _notebook = notebook_;
    OneDriverHttp.instance.notebook = notebook_!;
  }


  OneDriverHttp? get http => OneDriverHttp.instance;

  Future<void> connect(callback) async {
    await _stopHttpServer();
    if (await _initHttpServer()) {
      launchUrl(Uri.parse(GET_CODE)).then(callback);
    }
  }

  Future<bool> _initHttpServer() async {
    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_parseCode);
    httpServer = await shelf_io.serve(handler, '0.0.0.0', 53789, shared: true);
    httpServer?.autoCompress = true;
    debugPrint(
      'Serving at http://${httpServer?.address.host}:${httpServer?.port}',
    );
    return true;
  }
  Future<void> _stopHttpServer() async {
    if (httpServer != null) {
      await httpServer?.close();
    }
  }

  Future<shelf.Response> _parseCode(shelf.Request request) async {
    if (request.url.queryParameters.isNotEmpty) {
      String? code = request.url.queryParameters['code'];
      if (code != null) {
        await _stopHttpServer();
        Map<String,dynamic>? tokenInfo = await requestTokenByCode(code);
        if (tokenInfo != null) {
          // String displayName=await getUserInfo();
          // notebook?.name =displayName;
          // NotebookController.to.saveNotebookData(onlySaveNotebook: true);
          // RemoteController.to.init(notebook!);
          OneDriverHttp.instance.cloudConfig=tokenInfo;
          syncNotebook();
          return shelf.Response.ok('<html> <head> </head> <body><script>window.close();</script></body> </html>',headers: {'Content-Type': 'text/html'},);
        }else{
          return shelf.Response.ok(
            '<html> <head> </head> <body>one drive 登陆失败！</body> </html>',
            headers: {'Content-Type': 'text/html'},
          );
        }

      }
    }
    return shelf.Response.ok('failed to get code');
  }

  Future<Map<String,dynamic>?> requestTokenByCode(String code) async {
    debugPrint('requesting token by code...->$code');
    Map<String,dynamic>? tokenInfo = await http?.getToken(code);
    if (tokenInfo != null && tokenInfo['access_token'] != null) {
      // notebook?.cloud = "1";
      // notebook?.cloudConfig =jsonEncode({"remoteType": RemoteType.oneDrive.name,"tokenInfo":json.encode(tokenInfo)});
      // NotebookController.to.saveNotebookData(onlySaveNotebook: true);
      debugPrint('tokenInfo->$tokenInfo');
      return tokenInfo;
    }
  }

  Future<String?> requestTokenByRefreshToken(String refreshToken) async {
    debugPrint('requesting token by refreshToken...->$refreshToken');
    Map? tokenInfo = await http?.getTokenByRefreshToken(refreshToken);
    // refresh token 失效
    if (tokenInfo?['error'] != null) {
      await RemoteController.to.connect(RemoteType.oneDrive);
      return null;
    }
    if (tokenInfo != null) {
      notebook?.cloudConfig =jsonEncode({"remoteType": RemoteType.oneDrive.name,"tokenInfo":json.encode(tokenInfo)});
      NotebookController.to.saveNotebookData(onlySaveNotebook: true);
      debugPrint('tokenInfo->$tokenInfo');
      return tokenInfo['access_token'];
    }
  }
  //获取用户信息
  Future<String> getUserInfo() async {
    //List<int>? avatarBytes = await http?.getUserAvatar();
    //File('D:\\dd.png').writeAsBytes(avatarBytes!);
    Map? userInfo = await http?.getUserInfo();
    if (userInfo != null) {
      notebook?.icon =jsonEncode(userInfo);
      NotebookController.to.saveNotebookData(onlySaveNotebook: true);
      return userInfo['displayName'];
    }
    return '';
  }
  /// 同步
  Future<void> syncNotebook({bool includeNote = true}) async {
    NotebookController.to.updateStatusText('syncing'.tr);

    Map? xNoteBookDir = await mkdir('/Apps/XNote');
    List<Map>? items = [];
    if (xNoteBookDir != null) {
      items = await http?.listItemsInfo(xNoteBookDir['id']);
    }
    String rootPath;
    Map? noteBookDir;
    if (items != null && items.isNotEmpty) {
      //如果远程存在笔记
      rootPath = '/Apps/XNote/${items.first['name']}';
      noteBookDir = items.first;
      String? content = await http?.getItemContent(
        noteBookDir['name'].toString(),
        rootPath,
      );
      if (noteBookDir['name'] != notebook?.id) {
        //如果笔记id不一致
        Notebook newNotebook = Notebook.fromJson(jsonDecode(content!));
        await NotebookController.to.changeNotebook(newNotebook);
        if(includeNote) await syncNoteBookTree("download");
      } else {
        //如果笔记id一致
        Notebook? local = notebook?.copyWith();
        Notebook? remote = Notebook.fromJson(jsonDecode(content!));

        if(local!.diaryCata!=remote!.diaryCata){
          await mergeTreeNode(DiaryController.to.diaryTreeNodes, transJson2Tree(remote!.diaryCata));
        }
        if(local!.noteCata!=remote!.noteCata){
           await mergeTreeNode(DocumentController.to.documentTreeNodes, transJson2Tree(remote!.noteCata));
         }
         notebook?.name=remote.name;
         notebook?.cloud='1';
         NotebookController.to.saveNotebookData(onlySaveNotebook: true);
      }
    } else {
      //如果远程不存在
      rootPath = '/Apps/XNote/${notebook?.id}';
      noteBookDir = await mkdir(rootPath);
      if (noteBookDir != null) {
        await http?.addFile(notebook!.id.toString(),json.encode(notebook),noteBookDir['id'],);
        notebook?.cloud='1';
        notebook?.cloudConfig=jsonEncode({"remoteType": RemoteType.oneDrive.name,"tokenInfo":http?.cloudConfig});
        await RemoteController.to.init(notebook!);
        await NotebookController.to.saveNotebookData(onlySaveNotebook: true);
      }
      if(includeNote) await syncNoteBookTree("upload");
    }

    NotebookController.to.updateStatusText('synced'.tr,delayCancel: 2000);
  }
  Future<void> mergeTreeNode(List<TreeType<TreeNodeType>> localChildren, List<TreeType<TreeNodeType>> remoteChildren) async{
    for (var treeType in localChildren) {
      TreeType<TreeNodeType>? treeTypeRemote =remoteChildren.firstWhereOrNull((element) {
        return element.data.note?.id==treeType.data.note?.id;
      });
      if(treeTypeRemote!=null){
        Note? localNote =await SystemController.to.database.noteDao.findNoteById(treeType.data!.note!.id!).first;
        int localUpdateTime=localNote?.updateTime??0;
        int remoteUpdateTime=treeTypeRemote?.data.note?.updateTime??0;
        if(remoteUpdateTime > localUpdateTime){
          String? content = await http?.getItemContent(treeTypeRemote!.data!.note!.id!, '/Apps/XNote/${notebook?.id}');
          if(content != null&&content!='null'){
            Note note = Note.fromJson(jsonDecode(content));
            //downloadAttachment(note.content!);
            await SystemController.to.database.noteDao.insertNote(note);
          }
        }
        if(remoteUpdateTime < localUpdateTime){
          await http?.addFileByPath(treeType.data!.note!.id!, jsonEncode(treeType.data!.note!), '/Apps/XNote/${notebook?.id}');
          await uploadAttachment(treeType.data.note!.content!);
        }
        await mergeTreeNode(treeType.children??[],treeTypeRemote.children??[]);
      }else{
        await syncNote(treeType, "upload");
      }
    }
    // 遍历远程树
    for (var treeType in remoteChildren) {
      TreeType<TreeNodeType>? treeTypeLocal =localChildren.firstWhereOrNull((element) {
        return element.data.note?.id==treeType.data.note?.id;
      });
      if(treeTypeLocal==null){
        await syncNote(treeType, "download");
        localChildren.add(treeType);
      }
    }
  }
  ///上传
  Future<Map> uploadNotebook(Notebook notebook_) async {
    String rootPath = '/Apps/XNote/${notebook_.id}';
    Map? map = await http?.addFileByPath(notebook_.id.toString(),json.encode(notebook_), rootPath);
    return map!;
  }
  Future<String?> downloadNotebook(Notebook notebook_) async {
    String rootPath = '/Apps/XNote/${notebook_.id}';
    String? content = await http?.getItemContent(notebook_.id.toString(),rootPath,);
    if(content != null&&content!='null'){
      Notebook newNotebook = Notebook.fromJson(jsonDecode(content!));
      await NotebookController.to.changeNotebook(newNotebook);
    }
    return content;
  }
  Future<void> syncNoteBookTree(
    String direction) async {
    if (direction == "upload") {
      for (TreeType<TreeNodeType> node in DiaryController.to.diaryTreeNodes) {
        await syncNote(node, "upload");
      }
      for (TreeType<TreeNodeType> node in DocumentController.to.documentTreeNodes) {
        await syncNote(node, "upload");
      }
    }
    if (direction == "download") {
      for (TreeType<TreeNodeType> node   in DiaryController.to.diaryTreeNodes) {
        await syncNote(node, "download");
      }
      for (TreeType<TreeNodeType> node   in DocumentController.to.documentTreeNodes) {
        await syncNote(node, "download");
      }
    }

  }

  Future<void> syncNote(
    TreeType<TreeNodeType> parentNode,
    String direction
  ) async {
    if(direction == "upload"){
       await http?.addFileByPath(parentNode.data!.note!.id!, jsonEncode(parentNode.data!.note!), '/Apps/XNote/${notebook?.id}');
       await uploadAttachment(parentNode.data!.note!.content!);
       if(parentNode.children != null){
         for(TreeType<TreeNodeType> node in parentNode.children!){
           await syncNote(node, "upload");
         }
       }
    }
    if(direction == "download"){
      String? content = await http?.getItemContent(parentNode.data!.note!.id!, '/Apps/XNote/${notebook?.id}');
      if(content != null&&content!='null'){
        Note note = Note.fromJson(jsonDecode(content));
        //downloadAttachment(note.content!);
        await SystemController.to.database.noteDao.insertNote(note);
      }
      if(parentNode.children != null){
        for(TreeType<TreeNodeType> node in parentNode.children!){
          await syncNote(node, "download");
        }
      }
    }
  }
  Future<void> syncNoteSingle(
      TreeNodeType parentNode,
      ) async {
    String? noteId=parentNode.note?.id;
    String? content = await http?.getItemContent(parentNode.note!.id!, '/Apps/XNote/${notebook?.id}');
    if(content != null&&content!='null'){
      Note remote = Note.fromJson(jsonDecode(content));
      //下载
      await downloadAttachment(remote.content!);
      if(remote!.updateTime! > parentNode.note!.updateTime!){
         Note? existingNote = await SystemController.to.database.noteDao.findNoteById(remote.id!).first;
         if(existingNote != null){
           await SystemController.to.database.noteDao.updateNote(remote);
         }else{
           await SystemController.to.database.noteDao.insertNote(remote);
         }
         if(NotebookController.to.currentTreeNote?.data.note?.id==noteId){
           await NotebookController.to.reloadTreeNode();
         }
      }

      if(remote!.updateTime! < parentNode.note!.updateTime!){
        await http?.addFileByPath(parentNode.note!.id!, jsonEncode(parentNode.note!), '/Apps/XNote/${notebook?.id}');
        await uploadAttachment(parentNode.note!.content!);
      }
    }else{
      String content=parentNode?.note?.pureContent??"";
      if(content.isNotEmpty){
        await http?.addFileByPath(parentNode.note!.id!, jsonEncode(parentNode.note!), '/Apps/XNote/${notebook?.id}');
        await uploadAttachment(parentNode.note!.content!);
      }
    }
  }
  Future<void> uploadAttachment(String content) async {
    List<String> files = getFilesFromNote(content);
    for (String file in files) {
      if (file.isNotEmpty) {
        Map? item = await http?.getItemInfo('/Apps/XNote/${notebook?.id}/files/$file');
        if (item?['error'] != null) {
          await http?.addAttachment(file, '/Apps/XNote/${notebook?.id}/files');
        }
      }
    }
  }
  Future<void> downloadAttachment(String content) async {
    List<String> files = getFilesFromNote(content);
    for (String file in files) {
      if (file.isNotEmpty) {
          await http?.downloadAttachment(file, '/Apps/XNote/${notebook?.id}/files');
      }
    }
  }
  Future<Map?> mkdir(String filePath) async {
    String p = '';
    int index = 0;
    Map? parentItem;
    for (String c in filePath.split("/")) {
      if (c == null || c.isEmpty) continue;
      p += '/$c';
      Map? item = await http?.getItemInfo(p);
      if (item?['error'] != null) {
        if (index == 0) {
          parentItem = await http?.addRootFolder(c);
        } else {
          parentItem = await http?.addFolder(c, parentItem?['id']);
        }
      } else {
        parentItem = item;
      }
      index++;
    }
    return parentItem;
  }
}

