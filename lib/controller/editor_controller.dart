import 'package:XNote/controller/remote_controller.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:get/get.dart' as g;

import '../pages/left/tree_node.dart';
import 'notebook_controller.dart';

class EditorController extends g.GetxController {
  static EditorController get to => g.Get.find();
  EditorState editorState=EditorState.blank(withInitialText: true);
  TreeNodeType? treeNodeType;
  void setEditorState(EditorState editorState,TreeNodeType? treeNodeType){

    this.editorState=editorState;
    this.treeNodeType=treeNodeType;
    // this.editorState.reload();
    // this.editorState.selectionNotifier.addListener(() async{
    //   if(!editable){
    //     editable=true;
    //     await RemoteController.to.syncNoteSingle(treeNodeType!);
    //   }
    // });
    update();
  }
  Future<void> deleteNode(Node  node) async{
    Transaction transaction=editorState.transaction;
     transaction.deleteNode(node);
     editorState.apply(transaction);
     await NotebookController.to.saveNote(NotebookController.to.currentTreeNote!.data);
     update();
  }
}