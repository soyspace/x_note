import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/controller/system_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../pages/left/tree_node.dart';
import '../storage/entity/note.dart';
import '../storage/entity/notebook.dart';
import '../utils/note_utils.dart';

class DocumentController  extends GetxController{
  static DocumentController get to => Get.find();

  late Notebook _notebook;
  final List<TreeType<TreeNodeType>> _documentTreeNodes = [];
  List<TreeType<TreeNodeType>> get documentTreeNodes => _documentTreeNodes;
  List<Note>  searchedNotes=[];
  List<TreeType<TreeNodeType>> ? _filterDocumentTreeNodes;
  List<TreeType<TreeNodeType>> get filterDocumentTreeNodes => _filterDocumentTreeNodes??_documentTreeNodes;
  bool onSearching=false;
  @override
  void onInit() {
    super.onInit();
    addListener((){
      NotebookController.to.listenNoteSaveQueue();
    });
  }

  Future<void> init(Notebook notebook) async {
    _notebook = notebook;
    _documentTreeNodes.clear();
    if(_notebook.noteCata.isNotEmpty) {
      _documentTreeNodes.addAll(transJson2Tree(_notebook.noteCata));
    }
    update();
  }

  ///新建文档
  void newDocument(TreeType<TreeNodeType>? parent_, String? name) async{
    Note note = Note.fromNullDocument(_notebook?.id,name);
    TreeType<TreeNodeType> treeNote = TreeType<TreeNodeType>(
      data: TreeNodeType.fromNote(note),
      children: [],
      parent: parent_,
    );
    if(parent_==null){
      documentTreeNodes.add(treeNote);
      parent_?.data.isExpanded=true;
    }else{
      parent_.children.add(treeNote);
    }
    await SystemController.to.database.noteDao.insertNote(note);
    NotebookController.to.setCurrentTreeNote(treeNote,[]);
    await NotebookController.to.saveNotebookData();
    update();
  }
  Future<void> searchNodes(String keyword) async{
    if(keyword=='%%'){
      onSearching==false;
      _filterDocumentTreeNodes=null;
      searchedNotes.clear();
      //clear searchedSummaryWidgets
      filterSearchResult(_documentTreeNodes.map((d)=>cloneTreeType(d,null)).toList(),[]);
      update();
      return;
    }
    onSearching=true;
    update();
    searchedNotes =await SystemController.to.database.noteDao.findDocumentNotesByContent(keyword);
    debugPrint("searchNodes:${searchedNotes.length}");
    ///添加搜索结果
    addSearchedSummary(searchedNotes,keyword);

    _filterDocumentTreeNodes = filterSearchResult(_documentTreeNodes.map((d)=>cloneTreeType(d,null)).toList(),searchedNotes);
    //_diaryTreeNodes.clear();
    //_diaryTreeNodes.addAll(filters);
    update();
    onSearching=false;
  }

  Future<List<TreeType<TreeNodeType>>> findDeletedNodes() async{
    List<Note> deletedNotes = await SystemController.to.database.noteDao.findDeleteNotes();
    List<TreeType<TreeNodeType>> deletedNodes = [];
    for(var note in deletedNotes) {
      TreeType<TreeNodeType> ? node = findByIdRecursiveList(_documentTreeNodes, note.id ?? "");
      if(node!=null){
        node.data.note=note;
        deletedNodes.add(node);
      }
    }
    return deletedNodes;
  }
}