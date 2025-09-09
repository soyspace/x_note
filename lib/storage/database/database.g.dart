// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  NoteDao? _noteDaoInstance;

  NotebookDao? _notebookDaoInstance;

  SystemDao? _systemDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Note` (`id` TEXT, `notebookId` TEXT, `name` TEXT, `sync` TEXT, `icon` TEXT, `type` TEXT, `content` TEXT, `size` INTEGER, `ext` TEXT, `hash` TEXT, `pureContent` TEXT, `createTime` INTEGER, `updateTime` INTEGER, `removed` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Notebook` (`id` TEXT, `name` TEXT NOT NULL, `sync` TEXT NOT NULL, `icon` TEXT, `diaryCata` TEXT NOT NULL, `noteCata` TEXT NOT NULL, `createTime` INTEGER, `updateTime` INTEGER, `isDefault` TEXT NOT NULL, `removed` TEXT NOT NULL, `cloud` TEXT NOT NULL, `cloudConfig` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `System` (`id` INTEGER, `name` TEXT, `lock` TEXT, `lockPassword` TEXT, `lockInterval` INTEGER, `cacheDir` TEXT, `theme` TEXT, `language` TEXT, `createTime` TEXT, `updateTime` TEXT, PRIMARY KEY (`id`))');

        await database.execute(
            'CREATE VIEW IF NOT EXISTS `name` AS SELECT id,name FROM note');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  NoteDao get noteDao {
    return _noteDaoInstance ??= _$NoteDao(database, changeListener);
  }

  @override
  NotebookDao get notebookDao {
    return _notebookDaoInstance ??= _$NotebookDao(database, changeListener);
  }

  @override
  SystemDao get systemDao {
    return _systemDaoInstance ??= _$SystemDao(database, changeListener);
  }
}

class _$NoteDao extends NoteDao {
  _$NoteDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _noteInsertionAdapter = InsertionAdapter(
            database,
            'Note',
            (Note item) => <String, Object?>{
                  'id': item.id,
                  'notebookId': item.notebookId,
                  'name': item.name,
                  'sync': item.sync,
                  'icon': item.icon,
                  'type': item.type,
                  'content': item.content,
                  'size': item.size,
                  'ext': item.ext,
                  'hash': item.hash,
                  'pureContent': item.pureContent,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime,
                  'removed': item.removed
                },
            changeListener),
        _noteUpdateAdapter = UpdateAdapter(
            database,
            'Note',
            ['id'],
            (Note item) => <String, Object?>{
                  'id': item.id,
                  'notebookId': item.notebookId,
                  'name': item.name,
                  'sync': item.sync,
                  'icon': item.icon,
                  'type': item.type,
                  'content': item.content,
                  'size': item.size,
                  'ext': item.ext,
                  'hash': item.hash,
                  'pureContent': item.pureContent,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime,
                  'removed': item.removed
                },
            changeListener),
        _noteDeletionAdapter = DeletionAdapter(
            database,
            'Note',
            ['id'],
            (Note item) => <String, Object?>{
                  'id': item.id,
                  'notebookId': item.notebookId,
                  'name': item.name,
                  'sync': item.sync,
                  'icon': item.icon,
                  'type': item.type,
                  'content': item.content,
                  'size': item.size,
                  'ext': item.ext,
                  'hash': item.hash,
                  'pureContent': item.pureContent,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime,
                  'removed': item.removed
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Note> _noteInsertionAdapter;

  final UpdateAdapter<Note> _noteUpdateAdapter;

  final DeletionAdapter<Note> _noteDeletionAdapter;

  @override
  Future<List<Note>> findAllNotes() async {
    return _queryAdapter.queryList('SELECT * FROM Note',
        mapper: (Map<String, Object?> row) => Note(
            notebookId: row['notebookId'] as String?,
            id: row['id'] as String?,
            name: row['name'] as String?,
            sync: row['sync'] as String?,
            icon: row['icon'] as String?,
            type: row['type'] as String?,
            content: row['content'] as String?,
            size: row['size'] as int?,
            ext: row['ext'] as String?,
            hash: row['hash'] as String?,
            pureContent: row['pureContent'] as String?,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            removed: row['removed'] as String?));
  }

  @override
  Stream<List<String>> findAllNoteTitles() {
    return _queryAdapter.queryListStream('SELECT title FROM Note',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        queryableName: 'Note',
        isView: false);
  }

  @override
  Stream<Note?> findNoteById(String id) {
    return _queryAdapter.queryStream('SELECT * FROM Note WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Note(
            notebookId: row['notebookId'] as String?,
            id: row['id'] as String?,
            name: row['name'] as String?,
            sync: row['sync'] as String?,
            icon: row['icon'] as String?,
            type: row['type'] as String?,
            content: row['content'] as String?,
            size: row['size'] as int?,
            ext: row['ext'] as String?,
            hash: row['hash'] as String?,
            pureContent: row['pureContent'] as String?,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            removed: row['removed'] as String?),
        arguments: [id],
        queryableName: 'Note',
        isView: false);
  }

  @override
  Future<List<Note>> findNotesByTitle(String title) async {
    return _queryAdapter.queryList('SELECT * FROM Note WHERE title LIKE ?1',
        mapper: (Map<String, Object?> row) => Note(
            notebookId: row['notebookId'] as String?,
            id: row['id'] as String?,
            name: row['name'] as String?,
            sync: row['sync'] as String?,
            icon: row['icon'] as String?,
            type: row['type'] as String?,
            content: row['content'] as String?,
            size: row['size'] as int?,
            ext: row['ext'] as String?,
            hash: row['hash'] as String?,
            pureContent: row['pureContent'] as String?,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            removed: row['removed'] as String?),
        arguments: [title]);
  }

  @override
  Future<List<Note>> findDocumentNotesByContent(String pureContent) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Note WHERE pureContent LIKE ?1 and type=\"N\"',
        mapper: (Map<String, Object?> row) => Note(
            notebookId: row['notebookId'] as String?,
            id: row['id'] as String?,
            name: row['name'] as String?,
            sync: row['sync'] as String?,
            icon: row['icon'] as String?,
            type: row['type'] as String?,
            content: row['content'] as String?,
            size: row['size'] as int?,
            ext: row['ext'] as String?,
            hash: row['hash'] as String?,
            pureContent: row['pureContent'] as String?,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            removed: row['removed'] as String?),
        arguments: [pureContent]);
  }

  @override
  Future<List<Note>> findDiaryNotesByContent(String pureContent) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Note WHERE pureContent LIKE ?1 and type!=\"N\"',
        mapper: (Map<String, Object?> row) => Note(
            notebookId: row['notebookId'] as String?,
            id: row['id'] as String?,
            name: row['name'] as String?,
            sync: row['sync'] as String?,
            icon: row['icon'] as String?,
            type: row['type'] as String?,
            content: row['content'] as String?,
            size: row['size'] as int?,
            ext: row['ext'] as String?,
            hash: row['hash'] as String?,
            pureContent: row['pureContent'] as String?,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            removed: row['removed'] as String?),
        arguments: [pureContent]);
  }

  @override
  Future<List<Note>> findNotesByNotebook(String notebookId) async {
    return _queryAdapter.queryList('SELECT * FROM Note WHERE notebookId = ?1',
        mapper: (Map<String, Object?> row) => Note(
            notebookId: row['notebookId'] as String?,
            id: row['id'] as String?,
            name: row['name'] as String?,
            sync: row['sync'] as String?,
            icon: row['icon'] as String?,
            type: row['type'] as String?,
            content: row['content'] as String?,
            size: row['size'] as int?,
            ext: row['ext'] as String?,
            hash: row['hash'] as String?,
            pureContent: row['pureContent'] as String?,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            removed: row['removed'] as String?),
        arguments: [notebookId]);
  }

  @override
  Future<List<Note>> findDeleteNotes() async {
    return _queryAdapter.queryList('SELECT * FROM Note WHERE removed = \"1\"',
        mapper: (Map<String, Object?> row) => Note(
            notebookId: row['notebookId'] as String?,
            id: row['id'] as String?,
            name: row['name'] as String?,
            sync: row['sync'] as String?,
            icon: row['icon'] as String?,
            type: row['type'] as String?,
            content: row['content'] as String?,
            size: row['size'] as int?,
            ext: row['ext'] as String?,
            hash: row['hash'] as String?,
            pureContent: row['pureContent'] as String?,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            removed: row['removed'] as String?));
  }

  @override
  Future<void> insertNote(Note note) async {
    await _noteInsertionAdapter.insert(note, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertNotes(List<Note> notes) async {
    await _noteInsertionAdapter.insertList(notes, OnConflictStrategy.ignore);
  }

  @override
  Future<void> updateNote(Note note) async {
    await _noteUpdateAdapter.update(note, OnConflictStrategy.fail);
  }

  @override
  Future<void> deleteNote(Note note) async {
    await _noteDeletionAdapter.delete(note);
  }

  @override
  Future<void> deleteNotes(List<Note> notes) async {
    await _noteDeletionAdapter.deleteList(notes);
  }
}

class _$NotebookDao extends NotebookDao {
  _$NotebookDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _notebookInsertionAdapter = InsertionAdapter(
            database,
            'Notebook',
            (Notebook item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'sync': item.sync,
                  'icon': item.icon,
                  'diaryCata': item.diaryCata,
                  'noteCata': item.noteCata,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime,
                  'isDefault': item.isDefault,
                  'removed': item.removed,
                  'cloud': item.cloud,
                  'cloudConfig': item.cloudConfig
                },
            changeListener),
        _notebookUpdateAdapter = UpdateAdapter(
            database,
            'Notebook',
            ['id'],
            (Notebook item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'sync': item.sync,
                  'icon': item.icon,
                  'diaryCata': item.diaryCata,
                  'noteCata': item.noteCata,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime,
                  'isDefault': item.isDefault,
                  'removed': item.removed,
                  'cloud': item.cloud,
                  'cloudConfig': item.cloudConfig
                },
            changeListener),
        _notebookDeletionAdapter = DeletionAdapter(
            database,
            'Notebook',
            ['id'],
            (Notebook item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'sync': item.sync,
                  'icon': item.icon,
                  'diaryCata': item.diaryCata,
                  'noteCata': item.noteCata,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime,
                  'isDefault': item.isDefault,
                  'removed': item.removed,
                  'cloud': item.cloud,
                  'cloudConfig': item.cloudConfig
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Notebook> _notebookInsertionAdapter;

  final UpdateAdapter<Notebook> _notebookUpdateAdapter;

  final DeletionAdapter<Notebook> _notebookDeletionAdapter;

  @override
  Future<List<Notebook>> findAllNotebooks() async {
    return _queryAdapter.queryList('SELECT * FROM Notebook',
        mapper: (Map<String, Object?> row) => Notebook(
            id: row['id'] as String?,
            name: row['name'] as String,
            sync: row['sync'] as String,
            icon: row['icon'] as String?,
            diaryCata: row['diaryCata'] as String,
            noteCata: row['noteCata'] as String,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            isDefault: row['isDefault'] as String,
            removed: row['removed'] as String,
            cloud: row['cloud'] as String,
            cloudConfig: row['cloudConfig'] as String?));
  }

  @override
  Stream<List<String>> findAllNotebookNames() {
    return _queryAdapter.queryListStream('SELECT name FROM Notebook',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        queryableName: 'Notebook',
        isView: false);
  }

  @override
  Stream<Notebook?> findNotebookById(String id) {
    return _queryAdapter.queryStream('SELECT * FROM Notebook WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Notebook(
            id: row['id'] as String?,
            name: row['name'] as String,
            sync: row['sync'] as String,
            icon: row['icon'] as String?,
            diaryCata: row['diaryCata'] as String,
            noteCata: row['noteCata'] as String,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            isDefault: row['isDefault'] as String,
            removed: row['removed'] as String,
            cloud: row['cloud'] as String,
            cloudConfig: row['cloudConfig'] as String?),
        arguments: [id],
        queryableName: 'Notebook',
        isView: false);
  }

  @override
  Future<List<Notebook>> findNotebooksByName(String name) async {
    return _queryAdapter.queryList('SELECT * FROM Notebook WHERE name LIKE ?1',
        mapper: (Map<String, Object?> row) => Notebook(
            id: row['id'] as String?,
            name: row['name'] as String,
            sync: row['sync'] as String,
            icon: row['icon'] as String?,
            diaryCata: row['diaryCata'] as String,
            noteCata: row['noteCata'] as String,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            isDefault: row['isDefault'] as String,
            removed: row['removed'] as String,
            cloud: row['cloud'] as String,
            cloudConfig: row['cloudConfig'] as String?),
        arguments: [name]);
  }

  @override
  Future<List<Notebook>> findNotebooksCreatedAfter(String date) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Notebook WHERE createdAt > ?1',
        mapper: (Map<String, Object?> row) => Notebook(
            id: row['id'] as String?,
            name: row['name'] as String,
            sync: row['sync'] as String,
            icon: row['icon'] as String?,
            diaryCata: row['diaryCata'] as String,
            noteCata: row['noteCata'] as String,
            createTime: row['createTime'] as int?,
            updateTime: row['updateTime'] as int?,
            isDefault: row['isDefault'] as String,
            removed: row['removed'] as String,
            cloud: row['cloud'] as String,
            cloudConfig: row['cloudConfig'] as String?),
        arguments: [date]);
  }

  @override
  Future<void> insertNotebook(Notebook notebook) async {
    await _notebookInsertionAdapter.insert(
        notebook, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertNotebooks(List<Notebook> notebooks) async {
    await _notebookInsertionAdapter.insertList(
        notebooks, OnConflictStrategy.ignore);
  }

  @override
  Future<void> updateNotebook(Notebook notebook) async {
    await _notebookUpdateAdapter.update(notebook, OnConflictStrategy.fail);
  }

  @override
  Future<void> deleteNotebook(Notebook notebook) async {
    await _notebookDeletionAdapter.delete(notebook);
  }

  @override
  Future<void> deleteNotebooks(List<Notebook> notebooks) async {
    await _notebookDeletionAdapter.deleteList(notebooks);
  }
}

class _$SystemDao extends SystemDao {
  _$SystemDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _systemInsertionAdapter = InsertionAdapter(
            database,
            'System',
            (System item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'lock': item.lock,
                  'lockPassword': item.lockPassword,
                  'lockInterval': item.lockInterval,
                  'cacheDir': item.cacheDir,
                  'theme': item.theme,
                  'language': item.language,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime
                },
            changeListener),
        _systemUpdateAdapter = UpdateAdapter(
            database,
            'System',
            ['id'],
            (System item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'lock': item.lock,
                  'lockPassword': item.lockPassword,
                  'lockInterval': item.lockInterval,
                  'cacheDir': item.cacheDir,
                  'theme': item.theme,
                  'language': item.language,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime
                },
            changeListener),
        _systemDeletionAdapter = DeletionAdapter(
            database,
            'System',
            ['id'],
            (System item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'lock': item.lock,
                  'lockPassword': item.lockPassword,
                  'lockInterval': item.lockInterval,
                  'cacheDir': item.cacheDir,
                  'theme': item.theme,
                  'language': item.language,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<System> _systemInsertionAdapter;

  final UpdateAdapter<System> _systemUpdateAdapter;

  final DeletionAdapter<System> _systemDeletionAdapter;

  @override
  Future<List<System>> findAllSystems() async {
    return _queryAdapter.queryList('SELECT * FROM System',
        mapper: (Map<String, Object?> row) => System(
            id: row['id'] as int?,
            name: row['name'] as String?,
            lock: row['lock'] as String?,
            lockPassword: row['lockPassword'] as String?,
            lockInterval: row['lockInterval'] as int?,
            cacheDir: row['cacheDir'] as String?,
            theme: row['theme'] as String?,
            language: row['language'] as String?,
            createTime: row['createTime'] as String?,
            updateTime: row['updateTime'] as String?));
  }

  @override
  Stream<List<String>> findAllSystemNames() {
    return _queryAdapter.queryListStream('SELECT name FROM System',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        queryableName: 'System',
        isView: false);
  }

  @override
  Stream<System?> findSystemById(int id) {
    return _queryAdapter.queryStream('SELECT * FROM System WHERE id = ?1',
        mapper: (Map<String, Object?> row) => System(
            id: row['id'] as int?,
            name: row['name'] as String?,
            lock: row['lock'] as String?,
            lockPassword: row['lockPassword'] as String?,
            lockInterval: row['lockInterval'] as int?,
            cacheDir: row['cacheDir'] as String?,
            theme: row['theme'] as String?,
            language: row['language'] as String?,
            createTime: row['createTime'] as String?,
            updateTime: row['updateTime'] as String?),
        arguments: [id],
        queryableName: 'System',
        isView: false);
  }

  @override
  Future<List<System>> findSystemsByName(String name) async {
    return _queryAdapter.queryList('SELECT * FROM System WHERE name LIKE ?1',
        mapper: (Map<String, Object?> row) => System(
            id: row['id'] as int?,
            name: row['name'] as String?,
            lock: row['lock'] as String?,
            lockPassword: row['lockPassword'] as String?,
            lockInterval: row['lockInterval'] as int?,
            cacheDir: row['cacheDir'] as String?,
            theme: row['theme'] as String?,
            language: row['language'] as String?,
            createTime: row['createTime'] as String?,
            updateTime: row['updateTime'] as String?),
        arguments: [name]);
  }

  @override
  Future<List<System>> findSystemsByVersion(String version) async {
    return _queryAdapter.queryList('SELECT * FROM System WHERE version > ?1',
        mapper: (Map<String, Object?> row) => System(
            id: row['id'] as int?,
            name: row['name'] as String?,
            lock: row['lock'] as String?,
            lockPassword: row['lockPassword'] as String?,
            lockInterval: row['lockInterval'] as int?,
            cacheDir: row['cacheDir'] as String?,
            theme: row['theme'] as String?,
            language: row['language'] as String?,
            createTime: row['createTime'] as String?,
            updateTime: row['updateTime'] as String?),
        arguments: [version]);
  }

  @override
  Future<void> insertSystem(System system) async {
    await _systemInsertionAdapter.insert(system, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSystems(List<System> systems) async {
    await _systemInsertionAdapter.insertList(
        systems, OnConflictStrategy.ignore);
  }

  @override
  Future<void> updateSystem(System system) async {
    await _systemUpdateAdapter.update(system, OnConflictStrategy.fail);
  }

  @override
  Future<void> deleteSystem(System system) async {
    await _systemDeletionAdapter.delete(system);
  }

  @override
  Future<void> deleteSystems(List<System> systems) async {
    await _systemDeletionAdapter.deleteList(systems);
  }
}
