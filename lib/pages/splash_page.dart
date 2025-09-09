import 'package:XNote/controller/diary_controller.dart';
import 'package:XNote/controller/document_controller.dart';
import 'package:XNote/controller/editor_controller.dart';
import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/controller/system_controller.dart';
import 'package:XNote/service/onedrive_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../controller/left_controller.dart';
import '../controller/remote_controller.dart';
import '../service/application_data_storage.dart';
import '../service/clipboard_service.dart';
import '../widgets/running_rabbit_widget.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  GetIt getIt = GetIt.instance;
  @override
  void initState() {
    super.initState();
    _initService().then((_){
      Get.offNamed('/home');
    });
  }

  _initService() async{
    getIt.registerFactory<ClipboardService>(() => ClipboardService(),);
    getIt.registerSingleton<ApplicationDataStorage>(ApplicationDataStorage());
    // 初始化系统控制器
    Get.put<SystemController>(SystemController(),permanent: true);
    // 初始化日记本控制器
    Get.put<NotebookController>(NotebookController(),permanent:  true);
    // 初始化日记控制器
    Get.put<DiaryController>(DiaryController(),permanent:  true);
    // 初始化文档控制器
    Get.put<DocumentController>(DocumentController(),permanent:  true);
    // 初始化云盘控制器
    Get.put<RemoteController>(RemoteController(),permanent:  true);
    // 初始化编辑器
    Get.put<EditorController>(EditorController(),permanent:  true);
    // 左側控制
    Get.put<LeftController>(LeftController(),permanent:  true);
    //初始化系统
    await SystemController.to.initSystem();
    //初始化日记本
    await NotebookController.to.initNotebookData();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RunningRabbitWidget(),
            //const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}