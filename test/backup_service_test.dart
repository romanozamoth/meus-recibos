import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meus_recibos/services/backup_service.dart';

void main() {
  test('localiza conteúdo no formato padrão do backup', () {
    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest.json', '{}'))
      ..addFile(ArchiveFile('database/meus_recibos.db', 3, [1, 2, 3]));

    expect(
      BackupService.findEntryForRestore(archive, 'manifest.json'),
      isNotNull,
    );
    expect(
      BackupService.findEntryForRestore(
        archive,
        'database/meus_recibos.db',
      ),
      isNotNull,
    );
  });

  test('aceita backup encapsulado em pasta e com separador alternativo', () {
    final archive = Archive()
      ..addFile(ArchiveFile.string('Meus Recibos/manifest.json', '{}'))
      ..addFile(
        ArchiveFile(r'Meus Recibos\database\meus_recibos.db', 3, [1, 2, 3]),
      );

    expect(
      BackupService.findEntryForRestore(archive, 'manifest.json'),
      isNotNull,
    );
    expect(
      BackupService.findEntryForRestore(
        archive,
        'database/meus_recibos.db',
      ),
      isNotNull,
    );
  });
}
