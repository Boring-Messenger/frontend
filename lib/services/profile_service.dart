import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';
import 'firebase_service.dart';
import 'local_db_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _uuid = const Uuid();
  final _firebase = FirebaseService();

  Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('user_id');
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await prefs.setString('user_id', id);
    }
    return id;
  }

  Future<UserProfile?> loadLocalProfile() async {
    final db = await LocalDbService().database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await LocalDbService().database;
    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    try {
      await _firebase.setUserProfile(profile.userId, profile.toFirebaseJson());
    } catch (_) {
      // Add retry logic??
    }
  }
}
