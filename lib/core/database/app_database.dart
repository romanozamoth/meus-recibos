import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _databaseName = 'meus_recibos.db';
  static const _databaseVersion = 2;
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      p.join(databasePath, _databaseName),
      version: _databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createProfilesTable(db);
        await _createClientsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createClientsTable(db);
        }
      },
    );
  }

  static Future<void> _createProfilesTable(DatabaseExecutor db) async {
    await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            trade_name TEXT,
            document_type TEXT NOT NULL,
            document_number TEXT NOT NULL,
            service_type TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT,
            address TEXT,
            city TEXT NOT NULL,
            state TEXT NOT NULL,
            pix_key TEXT,
            pix_type TEXT,
            logo_path TEXT,
            color INTEGER NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_profiles_single_default '
      'ON profiles(is_default) WHERE is_default = 1',
    );
  }

  static Future<void> _createClientsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        document TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_clients_unique_document '
      "ON clients(document) WHERE document IS NOT NULL AND document <> ''",
    );
    await db.execute(
      'CREATE INDEX idx_clients_name ON clients(name COLLATE NOCASE)',
    );
  }
}
