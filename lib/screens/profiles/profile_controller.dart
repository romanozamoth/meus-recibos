import 'package:flutter/foundation.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:meus_recibos/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);
  final ProfileRepository _repository;
  List<Profile> _profiles = const [];
  bool _loading = false;
  String? _error;

  List<Profile> get profiles => List.unmodifiable(_profiles);
  bool get loading => _loading;
  String? get error => _error;
  Profile? get defaultProfile {
    for (final profile in _profiles) {
      if (profile.isDefault) return profile;
    }
    return null;
  }

  Future<void> loadProfiles() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profiles = await _repository.findAll();
    } catch (_) {
      _error = 'Não foi possível carregar os perfis.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Profile profile) async {
    await _repository.save(profile);
    await loadProfiles();
  }

  Future<void> setDefault(int id) async {
    await _repository.setDefault(id);
    await loadProfiles();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await loadProfiles();
  }
}
