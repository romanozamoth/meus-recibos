import 'dart:async';

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
      _recentReceipts = await _repository.findRecent(limit: 100);
    } catch (_) {
      _error = 'Não foi possível carregar os documentos.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AppDocument> saveDocumentWithPdf(
    AppDocument receipt,
    Profile profile,
  ) async {
    var saved = await _repository.saveNew(receipt);
    final bytes = await _pdfService.buildReceipt(saved, profile);
    final path = await _pdfService.saveReceipt(bytes, saved);
    saved = await _repository.updatePdfPath(saved.id!, path);
    _recentReceipts = [
      saved,
      ..._recentReceipts.where((document) => document.id != saved.id),
    ];
    notifyListeners();
    unawaited(loadRecentReceipts());
    return saved;
  }

  Future<AppDocument> updateBudgetStatus(
    AppDocument budget,
    String status,
    Profile profile,
  ) async {
    var updated = await _repository.updateStatus(budget.id!, status);
    final bytes = await _pdfService.buildReceipt(updated, profile);
    final path = await _pdfService.saveReceipt(bytes, updated);
    updated = await _repository.updatePdfPath(updated.id!, path);
    _recentReceipts = _recentReceipts
        .map((document) => document.id == updated.id ? updated : document)
        .toList();
    notifyListeners();
    unawaited(loadRecentReceipts());
    return updated;
  }

  Future<AppDocument?> findById(int id) => _repository.findById(id);
}
