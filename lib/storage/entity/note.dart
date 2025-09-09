import 'package:XNote/storage/entity/DiaryType.dart';
import 'package:floor/floor.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

@entity
class Note {
  @primaryKey
  String? id;
  String? notebookId;
  String? name;
  String? sync; // 1-待同步, 0-已同步
  String? icon;
  String? type; // 'Y'-年, 'M'-月, 'D'-日，'N'-笔记，'A'-附件
  String? content;
  int? size; // 文件大小
  String? ext; // 扩展名
  String? hash;
  String? pureContent; // 去除标签纯内容
  int? createTime;
  int? updateTime;
  String? removed; // 0-未删除, 1-已删除
  @ignore
  List<Widget>? searchedSummaryWidgets = [];
  Note({
    required this.notebookId,
    this.id,
    this.name,
    this.sync,
    this.icon,
    this.type,
    this.content,
    this.size,
    this.ext,
    this.hash,
    this.pureContent,
    this.createTime,
    this.updateTime,
    this.removed,
    this.searchedSummaryWidgets,
  });

  Note.fromJson(Map<String, dynamic> json) {
    id = json['id']!;
    notebookId = json['notebookId']!;
    name = json['name'];
    sync = json['sync'];
    icon = json['icon']??'0';
    type = json['type'];
    content = json['content'];
    size = json['size'];
    ext = json['ext'];
    hash = json['hash'];
    pureContent = json['pureContent'];
    createTime = json['createTime'];
    updateTime = json['updateTime'];
    removed = json['removed'];
  }
  Note.fromNullDiary(String? notebookId_,DiaryType dtype,String? _name) {
    var today = DateTime.now();
    if(_name==null){
      if(dtype==DiaryType.Y){
        name='${today.year}';
      }else if(dtype==DiaryType.M){
        name='${today.month}';
      }else if(dtype==DiaryType.D){
        name='${today.day}';
      }
    }else{
      name=_name;
    }
      id=Uuid().v1();
      notebookId=notebookId_;
      sync='0';
      createTime=today.millisecondsSinceEpoch ;
      updateTime=0;
      type=dtype.name;
      size=0;
      removed='0';
      content='';
      icon='';
      hash='';
      ext='';
      pureContent='';
  }
  Note.fromNullDocument(String? notebookId_,String? name_) {
    var today = DateTime.now();
    id=Uuid().v1();
    name=name_??'未命名';
    notebookId=notebookId_;
    sync='0';
    createTime=today.millisecondsSinceEpoch;
    updateTime=0;
    type=DiaryType.N.name;
    size=0;
    removed='0';
    content='';
    icon='';
    hash='';
    ext='';
    pureContent='';
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notebookId': notebookId,
      'name': name,
      //'sync': sync,  // 转换为数据库存储格式
      'icon': icon,
      'type': type,
      'content': content,
      'size': size,
      'ext': ext,
      //'hash': hash,
      'pureContent': pureContent,  // 保持与数据库字段一致
      'createTime': createTime,  // DateTime转字符串
      'updateTime': updateTime,
      'removed': removed,  // 转换为数据库存储格式
    };
  }
}
