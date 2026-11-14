import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VoteLocalStore {
  String _key(String uid) => 'sozsende_votes_$uid';

  Future<Map<String, int>> votes(String uid) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(uid));
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveVotes(String uid, Map<String, int> votes) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(uid), jsonEncode(votes));
  }

  Future<void> setVote(String uid, String pollKey, int index) async {
    final m = await votes(uid);
    m[pollKey] = index;
    await saveVotes(uid, m);
  }
}
