import 'package:flutter/foundation.dart';
import 'package:meus_recibos/models/client.dart';
import 'package:meus_recibos/repositories/client_repository.dart';

class ClientController extends ChangeNotifier {
  ClientController(this._repository);

  final ClientRepository _repository;
  List<Client> _clients = const [];
  bool _loading = false;
  String? _error;
  String _query = '';

  List<Client> get clients => List.unmodifiable(_clients);
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;

  Future<void> loadClients({String? query}) async {
    if (query != null) _query = query;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _clients = await _repository.findAll(query: _query);
    } catch (_) {
      _error = 'Não foi possível carregar os clientes.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Client client) async {
    await _repository.save(client);
    await loadClients();
  }

  Future<Client> saveFromDocument(Client client) async {
    final saved = await _repository.saveFromDocument(client);
    await loadClients();
    return saved;
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await loadClients();
  }
}
