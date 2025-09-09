import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/controller/remote_controller.dart';
import 'package:XNote/controller/system_controller.dart';
import 'package:XNote/utils/note_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../pages/left/tree_node.dart';
import '../storage/entity/DiaryType.dart';
import '../storage/entity/note.dart';
import '../storage/entity/notebook.dart';

class LeftController  extends GetxController{
  static LeftController get to => Get.find();
  bool onHover = false;
  NotebookController notebookController = Get.find();
  void onHoverChange(bool value){
    onHover = value;
    update(['logo','notebook']);
  }
}