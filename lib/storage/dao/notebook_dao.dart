import 'package:floor/floor.dart';

import '../entity/notebook.dart';

@dao
abstract class NotebookDao {
  @Query('SELECT * FROM Notebook')
  Future<List<Notebook>> findAllNotebooks();

  @Query('SELECT name FROM Notebook')
  Stream<List<String>> findAllNotebookNames();

  @Query('SELECT * FROM Notebook WHERE id = :id')
  Stream<Notebook?> findNotebookById(String id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertNotebook(Notebook notebook);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateNotebook(Notebook notebook);

  @delete
  Future<void> deleteNotebook(Notebook notebook);

  @Query('SELECT * FROM Notebook WHERE name LIKE :name')
  Future<List<Notebook>> findNotebooksByName(String name);

  @Query('SELECT * FROM Notebook WHERE createdAt > :date')
  Future<List<Notebook>> findNotebooksCreatedAfter(String date);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertNotebooks(List<Notebook> notebooks);

  @delete
  Future<void> deleteNotebooks(List<Notebook> notebooks);
}