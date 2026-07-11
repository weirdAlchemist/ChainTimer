import 'package:flutter/foundation.dart';

import '../models/timer_chain.dart';
import '../services/chain_storage.dart';

/// Holds the list of saved chains and keeps them persisted.
class ChainsProvider extends ChangeNotifier {
  ChainsProvider(this._storage);

  final ChainStorage _storage;

  List<TimerChain> _chains = [];
  bool _loaded = false;

  List<TimerChain> get chains => List.unmodifiable(_chains);
  bool get loaded => _loaded;

  Future<void> load() async {
    _chains = await _storage.load();
    _loaded = true;
    notifyListeners();
  }

  TimerChain? byId(String id) {
    for (final c in _chains) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Inserts [chain] if new, otherwise replaces the existing one with the same
  /// id (keeping its position in the list).
  Future<void> upsert(TimerChain chain) async {
    final idx = _chains.indexWhere((c) => c.id == chain.id);
    if (idx >= 0) {
      _chains[idx] = chain;
    } else {
      _chains.add(chain);
    }
    notifyListeners();
    await _storage.save(_chains);
  }

  Future<void> delete(String id) async {
    _chains.removeWhere((c) => c.id == id);
    notifyListeners();
    await _storage.save(_chains);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _chains.removeAt(oldIndex);
    _chains.insert(newIndex, item);
    notifyListeners();
    await _storage.save(_chains);
  }
}
