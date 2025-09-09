import 'dart:convert';

import 'package:XNote/controller/diary_controller.dart';
import 'package:XNote/controller/document_controller.dart';
import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/controller/system_controller.dart';
import 'package:XNote/service/onedrive_service.dart';
import 'package:XNote/storage/entity/notebook.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../pages/left/tree_node.dart';
import '../storage/entity/note.dart';

enum RemoteType{
  oneDrive,
  googleDrive;
}

class RemoteController  extends GetxController{
  static RemoteController get to => Get.find();
  Notebook? notebook;
  Map<String,dynamic>? cloudConfig;
  ///初始化
  Future<void> init(Notebook notebook) async{
    this.notebook=notebook;
    if(notebook.cloudConfig!=null&&notebook.cloudConfig!.isNotEmpty) {
      cloudConfig=jsonDecode(notebook.cloudConfig!);
    }
    OneDriveService.instance.notebook=notebook;
    ///初始化onedrive
    if(notebook.cloud=='1'&& cloudConfig?['remoteType']==RemoteType.oneDrive.name){
      await OneDriveService.instance.syncNotebook();
      await OneDriveService.instance.getUserInfo();
    }
  }
  ///连接远程
  Future<void> connect(RemoteType remoteType) async{
    if(remoteType==RemoteType.oneDrive){
      await OneDriveService.instance.connect(connectCallBack);
    }
  }
  ///同步笔记
  Future<void> syncNoteSingle(TreeNodeType parentNode) async{

    if(notebook?.cloud=='1'&& cloudConfig?['remoteType']==RemoteType.oneDrive.name){
      NotebookController.to.updateStatusText('${parentNode.note!.name}${'syncing'.tr}');
      await changeNoteSyncStatus(parentNode.note, '1');
      await OneDriveService.instance.syncNoteSingle(parentNode);
      await changeNoteSyncStatus(parentNode.note, '0');
      NotebookController.to.updateStatusText('${parentNode.note!.name}${'synced'.tr}',delayCancel: 2000);
    }

  }
  ///同步笔记本
  Future<void> uploadNotebook(Notebook notebook) async{
    if(notebook?.cloud=='1'&& cloudConfig?['remoteType']==RemoteType.oneDrive.name){
      await OneDriveService.instance.uploadNotebook(notebook);
    }
  }
  ///同步笔记本
  Future<void> downloadNotebook(Notebook notebook) async{
    if(notebook?.cloud=='1'&& cloudConfig?['remoteType']==RemoteType.oneDrive.name){
      await OneDriveService.instance.downloadNotebook(notebook);
    }
  }
  ///连接远程回调
  Future<void> connectCallBack(bool isSuccess) async{
     debugPrint("connectCallBack.."+isSuccess.toString());
     debugPrint("connectCallBack.."+notebook!.cloudConfig.toString());
  }
  ///修改笔记同步状态
  Future<void> changeNoteSyncStatus(Note? note,String sync) async{
    if(note==null) return;
    note.sync=sync;
    if(note.type=="N"){
      DocumentController.to.update();
    }else{
      DiaryController.to.update();
    }
  }
}