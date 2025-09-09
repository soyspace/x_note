import 'package:floor/floor.dart';

import '../entity/system.dart';

@dao
abstract class SystemDao {
  @Query('SELECT * FROM System')
  Future<List<System>> findAllSystems();

  @Query('SELECT name FROM System')
  Stream<List<String>> findAllSystemNames();

  @Query('SELECT * FROM System WHERE id = :id')
  Stream<System?> findSystemById(int id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSystem(System system);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateSystem(System system);

  @delete
  Future<void> deleteSystem(System system);

  @Query('SELECT * FROM System WHERE name LIKE :name')
  Future<List<System>> findSystemsByName(String name);

  @Query('SELECT * FROM System WHERE version > :version')
  Future<List<System>> findSystemsByVersion(String version);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSystems(List<System> systems);

  @delete
  Future<void> deleteSystems(List<System> systems);
}