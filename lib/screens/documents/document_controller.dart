import 'package:flutter/foundation.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/repositories/document_repository.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:meus_recibos/services/pdf_service.dart';

class DocumentController extends ChangeNotifier {
  DocumentController(this._repository, this._pdfService);

  final DocumentRepository _repository;
  final PdfService _pdfService;
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

  Future<AppDocument> saveReceiptWithPdf(
    AppDocument receipt,
    Profile profile,
  ) async {
    var saved = await _repository.saveNew(receipt);
    final bytes = await _pdfService.buildReceipt(saved, profile);
    final path = await _pdfService.saveReceipt(bytes, saved);
    saved = await _repository.updatePdfPath(saved.id!, path);
    await loadRecentReceipts();
    return saved;
  }
}
