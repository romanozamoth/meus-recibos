import 'package:flutter/foundation.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/repositories/document_repository.dart';

class DocumentController extends ChangeNotifier {
  DocumentController(this._repository);

  final DocumentRepository _repository;
  List<AppDocument> _recentReceipts = const [];
  bool _loading = false;
  String? _error;

  List<AppDocument> get recentReceipts => List.unmodifiable(_recentReceipts);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadRecentReceipts() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recentReceipts = await _repository.findRecent(
        type: DocumentType.receipt,
      );
    } catch (_) {
      _error = 'Não foi possível carregar os recibos.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AppDocument> saveReceipt(AppDocument receipt) async {
    final saved = await _repository.saveNew(receipt);
    await loadRecentReceipts();
    return saved;
  }
}
