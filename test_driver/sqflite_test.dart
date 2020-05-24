/*
 * Copyright 2020 Marco Gomiero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:friends_tournament/src/data/database/database_provider.dart';
import 'package:friends_tournament/src/data/database/local_data_source.dart';
import 'package:friends_tournament/src/data/setup_repository.dart';
import 'package:test/test.dart';

import 'FakeDatabaseProvider.dart';
import 'test_tournament.dart';

void main() {
  Future sleep([int milliseconds]) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  group('Tournament setup database checks', () {
    SetupRepository setupRepository;

    setUpAll(() {
      DatabaseProvider databaseProvider = FakeDatabaseProvider.get;
      LocalDataSource localDataSource = LocalDataSource(databaseProvider);

      setupRepository = SetupRepository(localDataSource);
      setupRepository.createTournament(
          TestTournament.playersNumber,
          TestTournament.playersAstNumber,
          TestTournament.matchesNumber,
          TestTournament.tournamentName,
          TestTournament.playersName,
          TestTournament.matchesName);
    });

    test('add new tournament with an active one in the db throws excetion',
        () async {
      await setupRepository.save();
      expect(() => setupRepository.save(),
          throwsA(isA<AlreadyActiveTournamentException>()));
    });

//    test('open null', () async {
//      var exception;
//      try {
//        await openDatabase(null);
//      } catch (e) {
//        exception = e;
//      }
//      expect(exception, isNotNull);
//    });
//    test('exists', () async {
//      expect(await databaseExists(inMemoryDatabasePath), isFalse);
//      var path = 'test_exists.db';
//      await deleteDatabase(path);
//      expect(await databaseExists(path), isFalse);
//      var db = await openDatabase(path);
//      try {
//        expect(await databaseExists(path), isTrue);
//      } finally {
//        await db?.close();
//      }
//    });
//    test('close in transaction', () async {
//      // await Sqflite.devSetDebugModeOn(true);
//      var path = 'test_close_in_transaction.db';
//      var factory = databaseFactory;
//      await deleteDatabase(path);
//      var db = await factory.openDatabase(path,
//          options: OpenDatabaseOptions(version: 1));
//      try {
//        await db.execute('BEGIN TRANSACTION');
//        await db.close();
//
//        db = await factory.openDatabase(path,
//            options: OpenDatabaseOptions(version: 1));
//      } finally {
//        await db.close();
//      }
//    });
//
//    /// Check if a file is a valid database file
//    ///
//    /// An empty file is a valid empty sqlite file
//    Future<bool> isDatabase(String path) async {
//      Database db;
//      var isDatabase = false;
//      try {
//        db = await openReadOnlyDatabase(path);
//        var version = await db.getVersion();
//        if (version != null) {
//          isDatabase = true;
//        }
//      } catch (_) {} finally {
//        await db?.close();
//      }
//      return isDatabase;
//    }
//
//    test('read_only missing database', () async {
//      var path = 'test_missing_database.db';
//      await deleteDatabase(path);
//      try {
//        var db = await openReadOnlyDatabase(path);
//        fail('should fail ${db?.path}');
//      } on DatabaseException catch (_) {}
//
//      expect(await isDatabase(path), isFalse);
//    });
//
//    test('read_only empty file', () async {
//      var path = 'empty_file_database.db';
//      await deleteDatabase(path);
//      var fullPath = join(await getDatabasesPath(), path);
//      await Directory(dirname(fullPath)).create(recursive: true);
//      await File(fullPath).writeAsString('');
//
//      // Open is fine, that is the native behavior
//      var db = await openReadOnlyDatabase(fullPath);
//      expect(await File(fullPath).readAsString(), '');
//
//      await db.getVersion();
//
//      await db.close();
//      expect(await File(fullPath).readAsString(), '');
//      expect(await isDatabase(fullPath), isTrue);
//    });
//
//    test('read_only missing bad format', () async {
//      var path = 'test_bad_format_database.db';
//      await deleteDatabase(path);
//      var fullPath = join(await getDatabasesPath(), path);
//      await Directory(dirname(fullPath)).create(recursive: true);
//      await File(fullPath).writeAsString('test');
//
//      // Open is fine, that is the native behavior
//      var db = await openReadOnlyDatabase(fullPath);
//      expect(await File(fullPath).readAsString(), 'test');
//      try {
//        var version = await db.getVersion();
//        print(await db.query('sqlite_master'));
//        fail('getVersion should fail ${db?.path} $version');
//      } on DatabaseException catch (_) {
//        // Android: DatabaseException(file is not a database (code 26 SQLITE_NOTADB)) sql 'PRAGMA user_version' args []}
//      }
//      await db.close();
//      expect(await File(fullPath).readAsString(), 'test');
//
//      expect(await isDatabase(fullPath), isFalse);
//      expect(await isDatabase(fullPath), isFalse);
//
//      expect(await File(fullPath).readAsString(), 'test');
//    });
//
//    test('multiple database', () async {
//      //await Sqflite.devSetDebugModeOn(true);
//      var count = 10;
//      var dbs = List<Database>(count);
//      for (var i = 0; i < count; i++) {
//        var path = 'test_multiple_$i.db';
//        await deleteDatabase(path);
//        dbs[i] =
//        await openDatabase(path, version: 1, onCreate: (db, version) async {
//          await db
//              .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
//          expect(
//              await db
//                  .rawInsert('INSERT INTO Test (name) VALUES (?)', ['test_$i']),
//              1);
//        });
//      }
//
//      for (var i = 0; i < count; i++) {
//        var db = dbs[i];
//        try {
//          var name = (await db.query('Test', columns: ['name']))
//              .first
//              .values
//              .first as String;
//          expect(name, 'test_$i');
//        } finally {
//          await db.close();
//        }
//      }
//
//      for (var i = 0; i < count; i++) {
//        var db = dbs[i];
//        await db.close();
//      }
//    });
//
////    test('version', () async {
////      // await Sqflite.devSetDebugModeOn(true);
////      var path = 'test_version.db';
////      await deleteDatabase(path);
////      var db = await openDatabase(path, version: 1);
////      try {
////        expect(await db.getVersion(), 1);
////        unawaited(db.close());
////
////        db = await openDatabase(path, version: 2);
////        expect(await db.getVersion(), 2);
////        unawaited(db.close());
////
////        db = await openDatabase(path, version: 1);
////        expect(await db.getVersion(), 1);
////        unawaited(db.close());
////
////        db = await openDatabase(path, version: 1);
////        expect(await db.getVersion(), 1);
////        expect(await isDatabase(path), isTrue);
////      } finally {
////        await db.close();
////      }
////      expect(await isDatabase(path), isTrue);
////    });
//
//    test('duplicated_column', () async {
//      // await Sqflite.devSetDebugModeOn(true);
//      var path = 'test_duplicated_column.db';
//      await deleteDatabase(path);
//      var db = await openDatabase(path);
//      try {
//        await db.execute('CREATE TABLE Test (col1 INTEGER, col2 INTEGER)');
//        await db.insert('Test', {'col1': 1, 'col2': 2});
//
//        var result = await db.rawQuery(
//            'SELECT t.col1, col1, t.col2, col2 AS col1 FROM Test AS t');
//        expect(result, [
//          {'col1': 2, 'col2': 2}
//        ]);
//      } finally {
//        await db.close();
//      }
//    });
//
//    test('indexed_param', () async {
//      final db = await openDatabase(':memory:');
//      expect(await db.rawQuery('SELECT ?1 + ?2', [3, 4]), [
//        {'?1 + ?2': 7}
//      ]);
//      await db.close();
//    });
//
//    test('deleteDatabase', () async {
//      // await devVerbose();
//      Database db;
//      try {
//        var path = 'test_delete_database.db';
//        await deleteDatabase(path);
//        db = await openDatabase(path);
//        expect(await db.getVersion(), 0);
//        await db.setVersion(1);
//
//        // delete without closing every time
//        await deleteDatabase(path);
//        db = await openDatabase(path);
//        expect(await db.getVersion(), 0);
//        await db.execute('BEGIN TRANSACTION');
//        await db.setVersion(2);
//
//        await deleteDatabase(path);
//        db = await openDatabase(path);
//        expect(await db.getVersion(), 0);
//        await db.setVersion(3);
//
//        await deleteDatabase(path);
//        db = await openDatabase(path);
//        expect(await db.getVersion(), 0);
//      } finally {
//        await db?.close();
//      }
//    });
  });
}
