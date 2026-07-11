import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_chain.dart';

/// Persists the user's [TimerChain]s locally as JSON in [SharedPreferences].
class ChainStorage {
  static const _key = 'chain_timer.chains.v1';

  Future<List<TimerChain>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => TimerChain.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt data — start clean rather than crash on launch.
      return [];
    }
  }

  Future<void> save(List<TimerChain> chains) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(chains.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
