import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:meus_recibos/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  BackupService(this._appDatabase);
  final AppDatabase _appDatabase;

  static const _formatVersion = 1;

  Future<File> createBackup() async {
    final database = await _appDatabase.database;
    await database.rawQuery('PRAGMA wal_checkpoint(FULL)');
    final databaseFile = File(await _appDatabase.filePath);
    if (!await databaseFile.exists()) {
      throw const FormatException('Banco de dados não encontrado.');
    }

    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({
            'app': 'meus_recibos',
            'format': _formatVersion,
            'created_at': DateTime.now().toIso8601String(),
          }),
        ),
      )
      ..addFile(
        ArchiveFile(
          'database/meus_recibos.db',
          await databaseFile.length(),
          await databaseFile.readAsBytes(),
        ),
      );

    final documents = await getApplicationDocumentsDirectory();
    await _addDirectory(
      archive,
      Directory(p.join(documents.path, 'profile_logos')),
      'profile_logos',
    );
    await _addDirectory(
      archive,
      Directory(p.join(documents.path, 'pdfs')),
      'pdfs',
    );

    final encoded = ZipEncoder().encode(archive);
    final temporary = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final file = File(
      p.join(temporary.path, 'meus-recibos-backup-$stamp.mrbak'),
    );
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }

  Future<void> restore(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final manifestEntry = findEntryForRestore(archive, 'manifest.json');
    final databaseEntry = findEntryForRestore(
      archive,
      'database/meus_recibos.db',
    );
    if (manifestEntry == null || databaseEntry == null) {
      throw const FormatException(
        'Arquivo de backup incompleto. Selecione o arquivo .mrbak exportado pelo aplicativo.',
      );
    }
    final manifest = jsonDecode(
      utf8.decode(manifestEntry.content as List<int>),
    );
    if (manifest is! Map ||
        manifest['app'] != 'meus_recibos' ||
        manifest['format'] != _formatVersion) {
      throw const FormatException('Formato de backup incompatível.');
    }
    final databaseBytes = Uint8List.fromList(
      databaseEntry.content as List<int>,
    );
    if (databaseBytes.length < 16 ||
        ascii.decode(databaseBytes.sublist(0, 15)) != 'SQLite format 3') {
      throw const FormatException('Banco de dados inválido.');
    }

    final temporary = await getTemporaryDirectory();
    final staged = File(p.join(temporary.path, 'restore_meus_recibos.db'));
    await staged.writeAsBytes(databaseBytes, flush: true);

    final currentPath = await _appDatabase.filePath;
    final currentFile = File(currentPath);
    final rollback = File('$currentPath.before_restore');
    await _appDatabase.close();
    if (await currentFile.exists()) await currentFile.copy(rollback.path);
    try {
      await staged.copy(currentPath);
      await _removeSidecars(currentPath);
      final restored = await _appDatabase.database;
      for (final table in const [
        'profiles',
        'clients',
        'documents',
        'document_items',
      ]) {
        await restored.rawQuery('SELECT 1 FROM $table LIMIT 1');
      }
      await _restoreAssets(archive, restored);
      if (await rollback.exists()) await rollback.delete();
    } catch (_) {
      await _appDatabase.close();
      if (await rollback.exists()) await rollback.copy(currentPath);
      await _removeSidecars(currentPath);
      await _appDatabase.database;
      rethrow;
    } finally {
      if (await staged.exists()) await staged.delete();
      if (await rollback.exists()) await rollback.delete();
    }
  }

  @visibleForTesting
  static ArchiveFile? findEntryForRestore(
    Archive archive,
    String expectedPath,
  ) {
    final expected = _normalizeArchivePath(expectedPath);
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final current = _normalizeArchivePath(entry.name);
      if (current == expected || current.endsWith('/$expected')) return entry;
    }
    return null;
  }

  static String _normalizeArchivePath(String value) {
    var normalized = value.replaceAll('\\', '/').trim().toLowerCase();
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  Future<void> _addDirectory(
    Archive archive,
    Directory directory,
    String prefix,
  ) async {
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final bytes = await entity.readAsBytes();
      archive.addFile(
        ArchiveFile('$prefix/${p.basename(entity.path)}', bytes.length, bytes),
      );
    }
  }

  Future<void> _restoreAssets(Archive archive, Database database) async {
    final documents = await getApplicationDocumentsDirectory();
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final parts = p.posix.split(_normalizeArchivePath(entry.name));
      if (parts.length < 2) continue;
      final assetDirectory = parts[parts.length - 2];
      if (!const {'profile_logos', 'pdfs'}.contains(assetDirectory)) continue;
      final fileName = p.posix.basename(parts.last);
      if (fileName != parts.last) {
        throw const FormatException('Caminho inválido no backup.');
      }
      final directory = Directory(p.join(documents.path, assetDirectory));
      await directory.create(recursive: true);
      await File(p.join(directory.path, fileName))
          .writeAsBytes(entry.content as List<int>, flush: true);
    }
    final logoDirectory = p.join(documents.path, 'profile_logos');
    final pdfDirectory = p.join(documents.path, 'pdfs');
    final profiles = await database.query(
      'profiles',
      columns: ['id', 'logo_path'],
    );
    for (final row in profiles) {
      final oldPath = row['logo_path'] as String?;
      if (oldPath == null) continue;
      await database.update(
        'profiles',
        {'logo_path': p.join(logoDirectory, p.basename(oldPath))},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    final documentsRows = await database.query(
      'documents',
      columns: ['id', 'pdf_path'],
    );
    for (final row in documentsRows) {
      final oldPath = row['pdf_path'] as String?;
      if (oldPath == null) continue;
      await database.update(
        'documents',
        {'pdf_path': p.join(pdfDirectory, p.basename(oldPath))},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> _removeSidecars(String databasePath) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final file = File('$databasePath$suffix');
      if (await file.exists()) await file.delete();
    }
  }
}
