import 'package:flutter/foundation.dart';
import 'package:meus_recibos/models/dashboard_summary.dart';
import 'package:meus_recibos/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);
  final DashboardRepository _repository;

  DashboardSummary? _summary;
  bool _loading = false;
  String? _error;

  DashboardSummary? get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _summary = await _repository.load(DateTime.now());
    } catch (_) {
      _error = 'Não foi possível carregar o painel.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
