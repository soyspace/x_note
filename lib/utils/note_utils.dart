import 'dart:convert';
import 'dart:ui';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import '../pages/left/tree_node.dart';
import '../storage/entity/note.dart';

/// 将 json 转换为 Tree
List<TreeType<TreeNodeType>> transJson2Tree(String json) {
  if (json.isEmpty) return [];
  return (jsonDecode(json) as List).map((e) {
    return convertMapToTree(e, null);
  }).toList();
}

///将 Map 转换为 Tree
TreeType<TreeNodeType> convertMapToTree(
  Map<String, dynamic> map,
  TreeType<TreeNodeType>? parent,
) {
  TreeType<TreeNodeType> tree = TreeType<TreeNodeType>(
    data: TreeNodeType.fromJson(map['data']),
    children: [],
    parent: parent,
  );
  tree.children =
      map['children']
          ?.map<TreeType<TreeNodeType>>(
            (child) => convertMapToTree(child, tree),
          )
          .toList();
  return tree;
}

///将 Tree 转换为 Map
Map convertTreeToMap(TreeType<TreeNodeType> tree) {
  Map<String, dynamic>? map = tree.data.note?.toJson();
  map?['content'] = '';
  map?['pureContent'] = '';
  return {
    'data': {
      'note': map, // 假设 Note 类有 toJson()
      //'isExpanded': tree.data.isExpanded,
      // 其他 TreeNodeType 属性...
    },
    'children': tree.children?.map(convertTreeToMap).toList(),
    'parent': null,
  };
}

/// 通过名称查找
TreeType<TreeNodeType>? findByName(
  List<TreeType<TreeNodeType>> tree,
  String name,
) {
  for (var node in tree) {
    if (node.data.note?.name == name) {
      return node;
    }
  }
  return null;
}

/// 通过 id 递归查找
TreeType<TreeNodeType>? findByIdRecursive(
  TreeType<TreeNodeType> tree,
  String id,
) {
  if (tree.data.note?.id == id) return tree;
  if (tree.children != null && tree.children.isNotEmpty) {
    for (TreeType<TreeNodeType> node in tree.children) {
      TreeType<TreeNodeType>? findNode = findByIdRecursive(node, id);
      if (findNode != null) return findNode;
    }
  }
  return null;
}

/// 通过 id 查找
TreeType<TreeNodeType>? findByIdRecursiveList(
  List<TreeType<TreeNodeType>> trees,
  String id,
) {
  for (TreeType<TreeNodeType> tree in trees) {
    var node = findByIdRecursive(tree, id);
    if (node != null) return node;
  }
  return null;
}

/// 生成面包屑
void generateBreadCrumbs(
  TreeType<TreeNodeType> leafNode,
  List<TreeType<TreeNodeType>> breadCrumbs_,
) {
  breadCrumbs_.add(leafNode);
  if (leafNode.parent != null) {
    generateBreadCrumbs(leafNode.parent!, breadCrumbs_);
  }
}
String generateTreeNodeTitle(TreeType<TreeNodeType> leafNode,) {
  List<TreeType<TreeNodeType>> breadCrumbs_=[];
  generateBreadCrumbs(leafNode, breadCrumbs_);
  return breadCrumbs_.reversed.map((e) => e.data.note?.name).join(' / ');
}
/// 获取纯文本
String getPlainText(EditorState state) {
  String plainText = '';
  state.document.root.children.forEach((element) {
    final textInserts = element.delta?.whereType<TextInsert>();
    textInserts?.forEach((element) {
      plainText = plainText + element.text;
    });
    if (element.type == 'image') {
      if(element.attributes['fileName'] != null){
        plainText = plainText + '[' + element.attributes['fileName'] + ']';
      }else{
        plainText = plainText + '[' + element.attributes['url'] + ']';
      }
    }
    if (element.type == 'file') {
      plainText = plainText + '[' + element.attributes['file_name'] + ']';
    }
  });
  return plainText;
}

List<String> getFilesFromNote(String content) {
  List<String> files = [];
  if (content.isEmpty) return files;
  Map<String, dynamic> json = jsonDecode(content);
  json['document']['children']?.forEach((element) {
    if (element['type'] == 'file' || element['type'] == 'image') {
      files.add(element['data']['url']);
    }
  });
  return files;
}

String fromDateTimeMillis(int millis) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
}

Map<String, Object> nodeToJson(Node node) {
  final map = <String, Object>{'type': node.type};
  if (node.children.isNotEmpty) {
    List<Node> children_ = [];
    for (var n in node.children) {
      if (n.type == 'paragraph' &&
          (n.attributes['delta'] == null ||
              (n.attributes['delta'] as List).isEmpty))
        continue;
      children_.add(n);
    }
    map['children'] = children_
        .map((n) => nodeToJson(n))
        .toList(growable: false);
  }
  if (node.attributes.isNotEmpty) {
    // filter the null value
    map['data'] = node.attributes..removeWhere((_, value) => value == null);
  }
  return map;
}

List<TreeType<TreeNodeType>> filterSearchResult(
  List<TreeType<TreeNodeType>> treeNodes,
  List<Note> searchedNotes,
) {
  List<TreeType<TreeNodeType>> filteredTreeNodes = [];
  for (var treeNode in treeNodes) {
    if (treeNode.children != null && treeNode.children.isNotEmpty) {
      treeNode.children = filterSearchResult(treeNode.children, searchedNotes);
    }
    if (isInNodeList(searchedNotes, treeNode.data.note!) ||
        treeNode.children.isNotEmpty) {
      filteredTreeNodes.add(treeNode);
    }
  }
  return filteredTreeNodes;
}

bool isInNodeList(List<Note> nodes, Note note) {
  note.searchedSummaryWidgets=[];
  for (var node in nodes) {
    if (node.id == note.id) {
      note.searchedSummaryWidgets=node.searchedSummaryWidgets;
      return true;
    }
  }
  return false;
}

TreeType<TreeNodeType> cloneTreeType<TreeNodeType extends AbsNodeType>(
  TreeType<TreeNodeType> tree,
  TreeType<TreeNodeType>? parent,
) {
  var newData = TreeType<TreeNodeType>(
    data: tree.data.clone<TreeNodeType>(),
    children: [],
    parent: parent,
    isChildrenLoadedLazily: tree.isChildrenLoadedLazily,
  );

  newData.children.addAll(
    tree.children.map((child) => cloneTreeType<TreeNodeType>(child, newData)).toList(),
  );

  return newData;
}

void addSearchedSummary(List<Note> searchedNodes,String keyWord_){
  String keyWord=keyWord_.replaceAll("%", "");
  for (var note in searchedNodes) {
      String pureContent=note.pureContent??"";
      if(!pureContent.contains(keyWord)) continue;
      note.searchedSummaryWidgets=[];
      int index=0;
      while(index>=0){
        index=pureContent.indexOf(keyWord,index);
        if(index<0) break;
        String preSearchedSummary=pureContent.substring(index-20<0?0:index-20,index);
        String nextSearchedSummary=pureContent.substring(index+keyWord.length,index+keyWord.length+20>pureContent.length?pureContent.length:index+keyWord.length+20);
        InlineSpan span = TextSpan(children: [
          TextSpan(text:preSearchedSummary, style: TextStyle(color: Colors.grey,fontStyle: FontStyle.italic)),
          TextSpan(text: keyWord, style: TextStyle(color: Colors.blue,fontWeight: FontWeight.bold,fontStyle: FontStyle.italic)),
          TextSpan(text: nextSearchedSummary, style: TextStyle(color: Colors.grey,fontStyle: FontStyle.italic)),
        ]);
        note.searchedSummaryWidgets?.add(Container(
          margin: EdgeInsets.only(bottom: 5),
          child: Text.rich(span),
        ));
        index=index+keyWord.length;
      }
  }
}
