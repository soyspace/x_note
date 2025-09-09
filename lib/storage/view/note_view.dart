import 'package:floor/floor.dart';

@DatabaseView('SELECT id,name FROM note', viewName: 'name')
class NoteView {
  final int id;
  final String name;

  NoteView(this.id,this.name);
}
