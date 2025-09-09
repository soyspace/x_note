import 'dart:async';
import 'dart:io';

import 'package:XNote/controller/diary_controller.dart';
import 'package:XNote/controller/document_controller.dart';
import 'package:XNote/controller/left_controller.dart';
import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/storage/entity/system.dart';
import 'package:floor/floor.dart' as floor;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../storage/database/database.dart';
import '../style/theme.dart';

class SystemController extends GetxController {
  static SystemController get to => Get.find();

  late System? system;
  late AppDatabase  _database;
  late String version;
  late PackageInfo packageInfo;
  AppDatabase get database => _database;
  int refreshTime = 0;
  Timer? _timer;
  Future<void> initSystem() async{
    await loadDatabase();
    packageInfo=await PackageInfo.fromPlatform();
    version = packageInfo.version;
    // 初始化数据库
    Directory cacheDir = await getApplicationSupportDirectory();
    system = await _database.systemDao.findSystemById(1).first;
    system ??= System(
      id: 1,
      name: 'XNote',
      lock: "0",
      lockPassword: '',
      lockInterval: 0,
      cacheDir: cacheDir.path,
      theme: 'light',
      language: 'en',
      createTime: DateTime.now().millisecondsSinceEpoch.toString(),
      updateTime: '',
    );

    debugPrint('cacheDir path: ${system?.cacheDir}');
    await _database.systemDao.insertSystem(system!);
    changeLanguage(system?.language??'en-US');
    changeTheme(system?.theme??'light');
    changeLock();
  }
  // 初始化数据库
  Future<void> loadDatabase() async {
    Directory docDirector = await getApplicationSupportDirectory();
    debugPrint('docDirector path: ${docDirector.path}');

    /// Initialize the database factory based on the platform
    await floor.sqfliteDatabaseFactory.setDatabasesPath(docDirector.path);
    _database = await $FloorAppDatabase.databaseBuilder('XNote.db').build();
    if (_database == null) {
      Get.snackbar('Error', 'Database not initialized');
      return;
    }
  }
  Future<void> changeCache(String cacheDir_) async{
    if(system?.cacheDir==cacheDir_) return;
    Directory cacheDir = Directory(cacheDir_);
    if(!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
    //将原缓存目录下文件转到新目录
    Directory oldCacheDir = Directory(system?.cacheDir??'');
    if(oldCacheDir.existsSync()){
      oldCacheDir.listSync(recursive: true).forEach((file) {
        if(file.existsSync()&&!file.path.endsWith('.db')){
          file.renameSync(p.join(cacheDir.path, file.path.split(Platform.pathSeparator).last));
          }
        });
    }
    system?.cacheDir = cacheDir_;
    await _database.systemDao.updateSystem(system!);
    update();
  }
  Future<void> clearCache() async{
    Directory cacheDir = Directory(system?.cacheDir??'');
    if(cacheDir.existsSync()){
      cacheDir.listSync().forEach((file) {
        if(file.existsSync()){
         if(!file.path.endsWith("XNote.db")) {
           file.delete(recursive: true);
         }
        }
      });
    }
  }
  Future<void> updateSystem() async{
    await _database.systemDao.updateSystem(system!);
    update();
  }

  Future<void> changeTheme(String mode) async{
    system?.theme = mode;
    Get.changeTheme(themeData[mode]?.$2??themeData['light']!.$2);

    await _database.systemDao.updateSystem(system!);
    update();
  }
  Future<void> changeLanguage(String language) async{
    var locale = Locale(
      language.split("_").first,
      language.split("_").last,
    );
    Get.updateLocale(locale);
    system?.language = language;
    updateSystem();
    NotebookController.to.update();
    DiaryController.to.update();
    DocumentController.to.update();
    LeftController.to.update();
  }

  Future<void> changeLock({String? lock, String? password, int? lockInterval}) async {
    if (lock != null) system?.lock = lock;
    if (password != null) system?.lockPassword = password;
    if (lockInterval != null) system?.lockInterval = lockInterval;
    await _database.systemDao.updateSystem(system!);
    update();

    String password0 = system?.lockPassword ?? '';
    int lockInterval0 = system?.lockInterval ?? 0;
    refreshTime = 0;
    if (system?.lock == '1' && password0.isNotEmpty && lockInterval0 > 0) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (refreshTime > lockInterval0) {
          Get.toNamed('/lock');
          _timer?.cancel();
        } else {
          refreshTime += 1;
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }
  void lockScreen(){
    String password0 = system?.lockPassword ?? '';
    int lockInterval0 = system?.lockInterval ?? 0;
    if (system?.lock == '1' && password0.isNotEmpty && lockInterval0 > 0) {
      Get.toNamed('/lock');
    }
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _database?.close();
  }
}
