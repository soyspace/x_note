import 'package:floor/floor.dart';

@entity
class System {
  @primaryKey
  final int? id;
   String? name;
   String? lock;
   String? lockPassword;
   int? lockInterval;
   String? cacheDir;
   String? theme;
   String? language;
  final String? createTime;
   String? updateTime;

  System({
     this.id,
     this.name,
     this.lock,
     this.lockPassword,
     this.lockInterval,
     this.cacheDir,
     this.theme,
     this.language,
     this.createTime,
     this.updateTime,
  });

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      id: json['id'] as int,
      name: json['name'] as String,
      lock: json['lock'],
      lockPassword: json['lock_password'] as String?,
      lockInterval: json['lock_interval'] as int,
      cacheDir: json['cache_dir'] as String,
      theme: json['theme'] as String,
      language: json['language'] as String,
      createTime: json['create_time'] as String,
      updateTime: json['update_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lock': lock,
      'lock_password': lockPassword,
      'lock_interval': lockInterval,
      'cache_dir': cacheDir,
      'theme': theme,
      'language': language,
      'create_time': createTime,
      'update_time': updateTime,
    };
  }
}