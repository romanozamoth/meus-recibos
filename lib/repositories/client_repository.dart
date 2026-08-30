import 'package:meus_recibos/core/database/app_database.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/models/client.dart';
import 'package:sqflite/sqflite.dart';

class DuplicateClientDocumentException implements Exception {
  const DuplicateClientDocumentException();
}

class ClientRepository {
  ClientRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<Client>> findAll({String query = ''}) async {
    final db = await _appDatabase.database;
    final text = query.trim();
    final digits = DocumentUtils.digitsOnly(text);
    final rows = text.isEmpty
        ? await db.query('clients', orderBy: 'name COLLATE NOCASE ASC')
        : await db.query(
            'clients',
            where: digits.isEmpty
                ? 'name LIKE ? COLLATE NOCASE'
                : 'name LIKE ? COLLATE NOCASE OR document LIKE ?',
            whereArgs: digits.isEmpty ? ['%$text%'] : ['%$text%', '%$digits%'],
            orderBy: 'name COLLATE NOCASE ASC',
          );
    return rows.map(Client.fromMap).toList();
  }

  Future<Client> save(Client client) async {
    final db = await _appDatabase.database;
    final document = DocumentUtils.digitsOnly(client.document ?? '');
    final values = client.toMap()
      ..remove('id')
      ..['name'] = client.name.trim()
      ..['document'] = document.isEmpty ? null : document
      ..['address'] = _optional(client.address);
    try {
      late final int id;
      if (client.id == null) {
        id = await db.insert('clients', values);
      } else {
        id = client.id!;
        await db.update('clients', values, where: 'id = ?', whereArgs: [id]);
      }
      final row = await db.query('clients', where: 'id = ?', whereArgs: [id]);
      return Client.fromMap(row.single);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const DuplicateClientDocumentException();
      }
      rethrow;
    }
  }

  Future<Client> saveFromDocument(Client client) async {
    final document = DocumentUtils.digitsOnly(client.document ?? '');
    if (document.isNotEmpty) {
      final existing = await findByDocument(document);
      if (existing != null) return existing;
    }
    return save(client);
  }

  Future<Client?> findByDocument(String value) async {
    final document = DocumentUtils.digitsOnly(value);
    if (document.isEmpty) return null;
    final db = await _appDatabase.database;
    final rows = await db.query(
      'clients',
      where: 'document = ?',
      whereArgs: [document],
      limit: 1,
    );
    return rows.isEmpty ? null : Client.fromMap(rows.single);
  }

  Future<void> delete(int id) async {
    final db = await _appDatabase.database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  static String? _optional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
