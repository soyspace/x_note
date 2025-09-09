import 'dart:io';
import 'package:XNote/controller/system_controller.dart';
import 'package:path/path.dart' as p;

class ApplicationDataStorage {

  String? getPath() {
     return   SystemController.to.system?.cacheDir!;
  }
  // Future<String> getImagePath() async {
  //   final path =  getPath();
  //   final imagePath = p.join(path!, 'images');
  //   final directory = Directory(imagePath);
  //   if (!directory.existsSync()) {
  //     directory.createSync(recursive: true);
  //   }
  //   return imagePath;
  // }
 Future<String> getFilesPath() async {
    final path =  getPath();
    final filesPath = p.join(path!, 'files');
    final directory = Directory(filesPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return filesPath;
  }
}