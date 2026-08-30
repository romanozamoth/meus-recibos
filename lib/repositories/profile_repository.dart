import 'package:meus_recibos/core/database/app_database.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:sqflite/sqflite.dart';

class ProfileRepository {
  ProfileRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<List<Profile>> findAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'profiles',
      orderBy: 'is_default DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile> save(Profile profile) async {
    final db = await _appDatabase.database;
    return db.transaction((transaction) async {
      final count =
          Sqflite.firstIntValue(
            await transaction.rawQuery('SELECT COUNT(*) FROM profiles'),
          ) ??
          0;
      final shouldBeDefault = profile.isDefault || count == 0;
      if (shouldBeDefault) {
        await transaction.update('profiles', {'is_default': 0});
      }

      final values = profile.toMap()
        ..remove('id')
        ..['is_default'] = shouldBeDefault ? 1 : 0;
      late final int id;
      if (profile.id == null) {
        id = await transaction.insert('profiles', values);
      } else {
        id = profile.id!;
        await transaction.update(
          'profiles',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      final row = await transaction.query(
        'profiles',
        where: 'id = ?',
        whereArgs: [id],
      );
      return Profile.fromMap(row.single);
    });
  }

  Future<void> setDefault(int id) async {
    final db = await _appDatabase.database;
    await db.transaction((transaction) async {
      await transaction.update('profiles', {'is_default': 0});
      await transaction.update(
        'profiles',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> delete(int id) async {
    final db = await _appDatabase.database;
    await db.transaction((transaction) async {
      final deleted = await transaction.query(
        'profiles',
        where: 'id = ?',
        whereArgs: [id],
      );
      await transaction.delete('profiles', where: 'id = ?', whereArgs: [id]);
      if (deleted.isNotEmpty && deleted.single['is_default'] == 1) {
        final next = await transaction.query(
          'profiles',
          limit: 1,
          orderBy: 'id ASC',
        );
        if (next.isNotEmpty) {
          await transaction.update(
            'profiles',
            {'is_default': 1},
            where: 'id = ?',
            whereArgs: [next.single['id']],
          );
        }
      }
    });
  }
}
