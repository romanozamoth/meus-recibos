import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LogoStorageService {
  Future<String> save(String sourcePath) async {
    final documents = await getApplicationDocumentsDirectory();
    final logos = Directory(p.join(documents.path, 'profile_logos'));
    if (!await logos.exists()) await logos.create(recursive: true);
    final extension = p.extension(sourcePath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final destination = p.join(
      logos.path,
      'logo_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    );
    return (await File(sourcePath).copy(destination)).path;
  }
}
