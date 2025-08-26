import 'dart:convert';

class QrService {
  static const _version = 1;

  String buildPayload({required String userId, required String username}) {
    final map = {
      'v': _version,
      'userId': userId,
      'username': username,
    };
    return jsonEncode(map);
  }

  ({String userId, String username})? parsePayload(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final v = map['v'];
      if (v != _version) return null;
      final userId = (map['userId'] as String?)?.trim();
      if (userId == null || userId.isEmpty) return null;
      final username = (map['username'] as String?)?.trim() ?? 'User';
      return (userId: userId, username: username);
    } catch (_) {
      return null;
    }
  }
}
