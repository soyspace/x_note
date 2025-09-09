import 'package:XNote/storage/entity/note.dart';
import 'package:floor/floor.dart';

@entity
class Notebook {
  @primaryKey
  String? id;
  String name;
  String sync;  // 从int改为String
  String? icon;
  @ignore
  List<Note>? diaryCataList;
  String diaryCata;// 日记分类
  @ignore
  List<Note>? noteCataList;// 日记分类
  String noteCata;// 记事分类
  int? createTime;
  int? updateTime;
  String isDefault;  // 从int改为String
  String removed;  // 从int改为String
  String cloud;  // 从int改为String
  String? cloudConfig;

  Notebook({
    required this.id,
    required this.name,
    required this.sync,
    this.icon,
    this.diaryCataList ,
    this.noteCataList,
    required this.diaryCata,
    required this.noteCata,
    required this.createTime,
    required this.updateTime,
    required this.isDefault,
    required this.removed,
    required this.cloud,
    this.cloudConfig,
  });

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'] as String,
      name: json['name'] as String,
      sync: json['sync'].toString(),  // 转换为String
      icon: json['icon'] as String?,
      diaryCata: json['diaryCata'] as String,
      noteCata: json['noteCata'] as String,
      createTime: json['createTime'] as int,
      updateTime: json['updateTime'] as int,
      isDefault: json['default'].toString(),  // 转换为String
      removed: json['removed'].toString(),  // 转换为String
      cloud: json['cloud'].toString(),  // 转换为String
      cloudConfig: json['cloudConfig'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sync': sync,
      'icon': icon,
      'diaryCata': diaryCata,
      'noteCata': noteCata,
      'createTime': createTime,
      'updateTime': updateTime,
      'isDefault': isDefault,
      'removed': removed,
      'cloud': cloud,
      'cloudConfig': cloudConfig,
    };
  }
  Notebook copyWith(){
    return Notebook(
      id: id,
      name: name,
      sync: sync,
      icon: icon,
      diaryCataList: diaryCataList,
      noteCataList: noteCataList,
      diaryCata: diaryCata,
      noteCata: noteCata,
      createTime: createTime,
      updateTime: updateTime,
      isDefault: isDefault,
      removed: removed,
      cloud: cloud,
      cloudConfig: cloudConfig,
       );
  }
}