// required package imports
import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;


import '../dao/note_dao.dart';
import '../dao/notebook_dao.dart';
import '../dao/system_dao.dart';
import '../entity/note.dart';
import '../entity/notebook.dart';
import '../entity/system.dart';
import '../view/note_view.dart';

part 'database.g.dart'; // the generated code will be there

/// flutter packages pub run build_runner build
/// flutter packages pub run build_runner watch.
/// 
@Database(version: 1, entities: [Note, Notebook, System],views: [NoteView])
abstract class AppDatabase extends FloorDatabase {
  NoteDao get noteDao;
  NotebookDao get notebookDao;
  SystemDao get systemDao;


}