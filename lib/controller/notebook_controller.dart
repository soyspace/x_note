import 'dart:collection';
import 'dart:convert';

import 'package:XNote/controller/diary_controller.dart';
import 'package:XNote/controller/document_controller.dart';
import 'package:XNote/controller/editor_controller.dart';
import 'package:XNote/controller/remote_controller.dart';
import 'package:XNote/controller/system_controller.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:uuid/uuid.dart';

import '../pages/left/tree_node.dart';
import '../storage/entity/note.dart';
import '../storage/entity/notebook.dart';
import '../utils/note_utils.dart';

GetIt getIt = GetIt.instance;

class NotebookController extends GetxController {
  static NotebookController get to => Get.find();
  SystemController systemController = Get.find();

  late Notebook currentNotebook;
  TreeType<TreeNodeType>? currentTreeNote;
  List<TreeType<TreeNodeType>> breadCrumbs = [];

  String statusText = '';

  ///笔记队列
  final Queue<TreeNodeType> _queue = Queue();
  Uuid uuid = Uuid();

  /// late EditorState editorState;

  ///加载日记
  Future<void> initNotebookData() async {
    //editorState = EditorState.blank(withInitialText: true);
    List<Notebook> notebooks =
        await systemController.database.notebookDao.findAllNotebooks();
    if (notebooks.isEmpty) {
      currentNotebook = Notebook(
        id: uuid.v1(),
        name: '我的第一本日记',
        icon: 'assets/icons/notebook.png',
        createTime: DateTime.now().millisecondsSinceEpoch,
        updateTime: 0,
        sync: '0',
        diaryCata: '',
        noteCata: '',
        isDefault: '1',
        cloud: '0',
        removed: '0',
      );
      await systemController.database.notebookDao.insertNotebook(
        currentNotebook!,
      );
    } else {
      currentNotebook =
          notebooks.firstWhereOrNull((item) => item.isDefault == '1')!;
    }
    await DiaryController.to.init(currentNotebook);
    await DocumentController.to.init(currentNotebook);
    await RemoteController.to.init(currentNotebook);
  }

  ///切换日记本
  Future<void> changeNotebook(Notebook notebook) async {
    notebook.isDefault = '1';
    if (notebook.id == currentNotebook.id) {
      await systemController.database.notebookDao.updateNotebook(notebook);
    } else {
      currentNotebook.isDefault = '0';
      await systemController.database.notebookDao.updateNotebook(
        currentNotebook,
      );
      await systemController.database.notebookDao.insertNotebook(notebook);
    }
    currentNotebook = notebook;
    // 初始化笔记
    await DiaryController.to.init(currentNotebook);
    await DocumentController.to.init(currentNotebook);
    await RemoteController.to.init(currentNotebook);
    update();
  }

  ///保存日记
  Future<void> saveNotebookData({bool onlySaveNotebook = false}) async {
    if (!onlySaveNotebook) {
      String diaryCata_ = jsonEncode(
        DiaryController.to.diaryTreeNodes.map(convertTreeToMap).toList(),
      );
      String noteCata_ = jsonEncode(
        DocumentController.to.documentTreeNodes.map(convertTreeToMap).toList(),
      );
      if (diaryCata_!= currentNotebook.diaryCata ||
          noteCata_ != currentNotebook.noteCata) {
        currentNotebook.updateTime = DateTime.now().millisecondsSinceEpoch;
        currentNotebook.diaryCata = diaryCata_;
        currentNotebook.noteCata = noteCata_;
        await RemoteController.to.uploadNotebook(currentNotebook);
      }
    }
    await systemController.database.notebookDao.updateNotebook(currentNotebook);
    update();
  }

  ///设置当前笔记
  Future<void> setCurrentTreeNote(
    TreeType<TreeNodeType> tree,
    List<TreeType<TreeNodeType>> breadCrumbs_,
  ) async {
    if (currentTreeNote != null &&
        currentTreeNote?.data.note?.id == tree.data.note?.id) {
      return;
    }
    //保存当前笔记
    if (currentTreeNote != null && currentTreeNote?.data.note?.sync != '1') {
      _queue.add(currentTreeNote!.data);
    }
    // 面包屑
    if (breadCrumbs_ == null || breadCrumbs_.isEmpty) {
      List<TreeType<TreeNodeType>> breadCrumbs_ = [];
      generateBreadCrumbs(tree, breadCrumbs_);
      breadCrumbs = breadCrumbs_.reversed.toList();
    } else {
      breadCrumbs = breadCrumbs_;
    }
    currentTreeNote = tree;

    await reloadTreeNode();

    //
    if (tree.data.note?.type != 'N') {
      DiaryController.to.update();
    } else {
      DocumentController.to.update();
    }
    update();
    update(['statusBar']);
  }

  ///重新从数据库加载笔记
  Future<void> reloadTreeNode() async {
    //TreeType<TreeNodeType> tree = currentTreeNote!;
    ///editorState.editable=editable_;
    //从数据库中获取数据
    Note? note =
        await systemController.database.noteDao
            .findNoteById(currentTreeNote!.data.note!.id!)
            .first;
    // 修复方案：添加空内容处理
    final content = note?.content;
    if (content == null || content.isEmpty) {
      currentTreeNote!.data.editorState = EditorState.blank(
        withInitialText: true,
      );
    } else {
      try {
        currentTreeNote!.data.editorState = EditorState(
          document: Document.fromJson(
            Map<String, Object>.from(json.decode(content)),
          ),
        );
      } catch (e) {
        // 如果JSON解析失败，也创建空白编辑器
        currentTreeNote!.data.editorState = EditorState.blank(
          withInitialText: true,
        );
      }
    }
    EditorController.to.setEditorState(
      currentTreeNote!.data.editorState!,
      currentTreeNote?.data,
    );
  }

  ///保存笔记
  Future<void> saveNote(TreeNodeType nodeType) async {
    if (nodeType.editorState == null) {
      debugPrint("error .... editorState is null");
      return;
    }
    String content = json.encode({
      'document': nodeToJson(nodeType.editorState!.document.root),
    });
    String pureContent = getPlainText(nodeType.editorState!);

    Note? existedNote =
        await systemController.database.noteDao
            .findNoteById(nodeType.note!.id!)
            .first;
    String existedPureContent = existedNote?.pureContent ?? '';
    if (pureContent == existedPureContent) return;

    updateStatusText('${nodeType.note!.name}${'saving'.tr}');

    nodeType.note!.updateTime = DateTime.now().millisecondsSinceEpoch;
    nodeType.note!.content = content;
    nodeType.note!.size = content.length;
    nodeType.note!.pureContent = pureContent;
    if (existedNote == null) {
      await systemController.database.noteDao.insertNote(
        nodeType.note ?? Note.fromNullDocument(currentNotebook?.id, null),
      );
    } else {
      await systemController.database.noteDao.updateNote(
        nodeType.note ?? Note.fromNullDocument(currentNotebook?.id, null),
      );
    }
    updateStatusText('${nodeType.note!.name}${'saved'.tr}', delayCancel: 2000);
    // 云盘同步
    await RemoteController.to.syncNoteSingle(nodeType);
    await saveNotebookData();
  }

  Future<void> rename(TreeNodeType nodeType, String name) async {
    Note? existedNote =await systemController.database.noteDao.findNoteById(nodeType.note!.id!).first;
    if (existedNote == null) {
      existedNote = Note.fromNullDocument(currentNotebook?.id, null);
      existedNote.name = name;
      await systemController.database.noteDao.insertNote(existedNote);
    } else {
      existedNote.name = name;
      await systemController.database.noteDao.updateNote(existedNote);
    }
    // 云盘同步
    nodeType.note = existedNote;
    await RemoteController.to.syncNoteSingle(nodeType);
    await saveNotebookData();
  }
  Future<void> remove(TreeNodeType nodeType,{bool recovery=false}) async {
    Note? existedNote =await systemController.database.noteDao.findNoteById(nodeType.note!.id!).first;
    if (existedNote == null) {
      existedNote = Note.fromNullDocument(currentNotebook?.id, null);
      existedNote.removed=recovery?'0':'1';
      await systemController.database.noteDao.insertNote(existedNote);
    } else {
      existedNote.removed=recovery?'0':'1';
      await systemController.database.noteDao.updateNote(existedNote);
    }
    // 云盘同步
    nodeType.note = existedNote;
    await RemoteController.to.syncNoteSingle(nodeType);
    await saveNotebookData();
  }
  ///笔记队列监听
  Future<void> listenNoteSaveQueue() async {
    while (_queue.isNotEmpty) {
      TreeNodeType? treeNodeType = _queue.removeFirst();
      if (treeNodeType != null && treeNodeType.note != null) {
        await saveNote(treeNodeType);
        treeNodeType.editorState = null;
      }
    }
  }

  void updateStatusText(String text, {int delayCancel = 0}) {
    statusText = text;
    update(["statusBar"]);

    if (delayCancel > 0) {
      Future.delayed(Duration(milliseconds: delayCancel), () {
        statusText = '';
        update(["statusBar"]);
      });
    }
  }
}
