import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _databaseName = 'meus_recibos.db';
  static const _databaseVersion = 4;
  Future<Database>? _databaseFuture;

  Future<Database> get database => _databaseFuture ??= _open();

  Future<Database> _open() async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      p.join(databasePath, _databaseName),
      version: _databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createProfilesTable(db);
        await _createClientsTable(db);
        await _createDocumentsTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createClientsTable(db);
        }
        if (oldVersion < 3) {
          await _createDocumentsTables(db);
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE documents ADD COLUMN pdf_path TEXT');
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

  static Future<void> _createDocumentsTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL UNIQUE,
        sequence INTEGER NOT NULL,
        year INTEGER NOT NULL,
        type TEXT NOT NULL,
        profile_id INTEGER NOT NULL,
        client_id INTEGER,
        client_name TEXT NOT NULL,
        client_document TEXT,
        client_address TEXT,
        date TEXT NOT NULL,
        due_date TEXT,
        valid_until TEXT,
        service_description TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        subtotal INTEGER NOT NULL,
        discount INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL,
        status TEXT NOT NULL,
        source_document_id INTEGER,
        pdf_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id),
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
        FOREIGN KEY (source_document_id) REFERENCES documents(id),
        UNIQUE(type, year, sequence)
      )
    ''');
    await db.execute('''
      CREATE TABLE document_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity_millis INTEGER NOT NULL,
        unit TEXT NOT NULL,
        unit_price INTEGER NOT NULL,
        total INTEGER NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_documents_date ON documents(date DESC)');
    await db.execute(
      'CREATE INDEX idx_document_items_document ON document_items(document_id)',
    );
  }
}
