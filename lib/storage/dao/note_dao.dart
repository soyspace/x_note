import 'package:floor/floor.dart';

import '../entity/note.dart';

@dao
abstract class NoteDao {
  @Query('SELECT * FROM Note')
  Future<List<Note>> findAllNotes();

  @Query('SELECT title FROM Note')
  Stream<List<String>> findAllNoteTitles();

  @Query('SELECT * FROM Note WHERE id = :id')
  Stream<Note?> findNoteById(String id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertNote(Note note);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateNote(Note note);

  @delete
  Future<void> deleteNote(Note note);

  @Query('SELECT * FROM Note WHERE title LIKE :title')
  Future<List<Note>> findNotesByTitle(String title);

  @Query('SELECT * FROM Note WHERE pureContent LIKE :pureContent and type="N"')
  Future<List<Note>> findDocumentNotesByContent(String pureContent);

  @Query('SELECT * FROM Note WHERE pureContent LIKE :pureContent and type!="N"')
  Future<List<Note>> findDiaryNotesByContent(String pureContent);

  @Query('SELECT * FROM Note WHERE notebookId = :notebookId')
  Future<List<Note>> findNotesByNotebook(String notebookId);

  @Query('SELECT * FROM Note WHERE removed = "1" ')
  Future<List<Note>> findDeleteNotes();

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertNotes(List<Note> notes);

  @delete
  Future<void> deleteNotes(List<Note> notes);
}