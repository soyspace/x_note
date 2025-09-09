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

class DiaryController  extends GetxController{
  static DiaryController get to => Get.find();
  late Notebook _notebook;
   final List<TreeType<TreeNodeType>> _diaryTreeNodes=[];

  List<TreeType<TreeNodeType>> get diaryTreeNodes => _diaryTreeNodes;
  List<Note>  searchedNotes=[];
  List<TreeType<TreeNodeType>> ? _filterDiaryTreeNodes;
  List<TreeType<TreeNodeType>> get filterDiaryTreeNodes => _filterDiaryTreeNodes??_diaryTreeNodes;

  bool onSearching=false;
  @override
  void onInit() {
    super.onInit();
    addListener((){
      NotebookController.to.listenNoteSaveQueue();
    });
  }
  ///创建日记
  Future<void> init(Notebook notebook) async {
    _notebook = notebook;
    _diaryTreeNodes.clear();
    if(_notebook.diaryCata.isNotEmpty) {
      _diaryTreeNodes.addAll(transJson2Tree(_notebook.diaryCata));
    }
    update();
  }

  ///写今天的日记
  Future<void> writeTodayNote({bool syncNotebookData=true}) async{
    TreeType<TreeNodeType>? dayNote=await checkTodayNoteExist();
    if(dayNote==null){
      if(syncNotebookData) await RemoteController.to.downloadNotebook(_notebook);
      dayNote =await checkTodayNoteExist(insert: true);
      NotebookController.to.saveNotebookData();
    }
    await NotebookController.to.setCurrentTreeNote(dayNote!,[]);
    update();
  }
  Future<TreeType<TreeNodeType>?> checkTodayNoteExist({bool insert=false}) async{
    var today = DateTime.now();
    //bool bookDateUpdated=false;
    //判断有没有年
    TreeType<TreeNodeType>? yearNote=findByName(_diaryTreeNodes, today.year.toString());
    if(yearNote==null){
      if(insert){
        yearNote=TreeType<TreeNodeType>(
          data: TreeNodeType.fromNote(Note.fromNullDiary(_notebook.id, DiaryType.Y, null)),
          children: [],
          parent: null,
        );
        await SystemController.to.database.noteDao.insertNote(yearNote.data.note!);
        diaryTreeNodes.add(yearNote);
      }else{
        return null;
      }
      //bookDateUpdated=true;
    }
    yearNote.data.isExpanded=true;
    //判断有没有月
    TreeType<TreeNodeType>? monthNote=findByName(yearNote!.children, today.month.toString());
    if(monthNote==null){
      if(insert){
        monthNote=TreeType<TreeNodeType>(
          data: TreeNodeType.fromNote(Note.fromNullDiary(_notebook.id, DiaryType.M, null)),
          children: [],
          parent: yearNote,
        );
        await SystemController.to.database.noteDao.insertNote(monthNote.data.note!);
        yearNote.children.add(monthNote);
      }else{
        return null;
      }
      //bookDateUpdated=true;
    }
    monthNote.data.isExpanded=true;
    //判断有没有天
    TreeType<TreeNodeType>? dayNote=findByName(monthNote!.children, today.day.toString());
    if(dayNote==null) {
      if(insert){
        dayNote = TreeType<TreeNodeType>(
          data: TreeNodeType.fromNote(
              Note.fromNullDiary(_notebook.id, DiaryType.D, null)),
          children: [],
          parent: monthNote,
        );
        //await SystemController.to.database.noteDao.insertNote(dayNote.data.note!);
        monthNote.children.add(dayNote);
      }else{
        return null;
      }
    }
    dayNote.data.isExpanded=true;
    return dayNote;
  }

  Future<void> searchNodes(String keyword) async{
    if(keyword=='%%'){
      onSearching==false;
      _filterDiaryTreeNodes=null;
      searchedNotes.clear();
      //clear searchedSummaryWidgets
      filterSearchResult(_diaryTreeNodes.map((d)=>cloneTreeType(d,null)).toList(),[]);
      update();
      return;
    }
    onSearching=true;
    update();
    searchedNotes =await SystemController.to.database.noteDao.findDiaryNotesByContent(keyword);
    debugPrint("searchNodes:${searchedNotes.length}");
    ///添加搜索结果
    addSearchedSummary(searchedNotes,keyword);

    _filterDiaryTreeNodes = filterSearchResult(_diaryTreeNodes.map((d)=>cloneTreeType(d,null)).toList(),searchedNotes);
    //_diaryTreeNodes.clear();
    //_diaryTreeNodes.addAll(filters);
    update();
    onSearching=false;
  }
}