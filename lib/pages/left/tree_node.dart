import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';

import '../../storage/entity/note.dart';

class TreeNodeType extends AbsNodeType {
  TreeNodeType({
    required super.id,
    required dynamic title,
    this.summary,
    super.isInner,
    this.note,
    this.level,
    this.editorState
  }) : super(title: title);

  String? summary;
  Note? note;
  int? level = 0;
  EditorState? editorState;
  FocusNode focusNode=FocusNode();
  TreeNodeType.fromNote(Note note)
    : this(id: note.id, title: note.name, note: note);

  @override
  T clone<T extends AbsNodeType>() {
    var newData = TreeNodeType(
      id: id,
      title: title,
      summary: summary,
      isInner: isInner,
    );
    newData.isUnavailable = isUnavailable;
    newData.isChosen = isChosen;
    newData.isExpanded = isExpanded;
    newData.isFavorite = isFavorite;
    newData.isBlurred = isBlurred;
    newData.isShowedInSearching = isShowedInSearching;
    newData.note = note;
    newData.focusNode = focusNode;
    return newData as T;
  }
  // 在 TreeNodeType 类中添加
  factory TreeNodeType.fromJson(Map<String, dynamic> json) {
      return TreeNodeType(
        id: json['note']['id'],
        title: json['note']['name'],
        note: json['note'] != null ? Note.fromJson(json['note']) : null,
        level: json['level'],
      );
  }

}
