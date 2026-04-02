import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  // 🔥 KEEP THESE (used everywhere in your app)
  static int? userId;
  static String? token;

  // 🔥 ADD THIS
  static const _storage = FlutterSecureStorage();

  static const _keyToken = "accessToken";
  static const _keyUserId = "userId";

  /// Save session (after OTP success)
  static Future<void> saveSession({
    required String token,
    required int? userId,
  }) async {
    // 👉 store in memory (existing usage)
    UserSession.token = token;
    UserSession.userId = userId;

    // 👉 store persistently (NEW)
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId.toString());
  }

  /// Load session (on app start)
  static Future<bool> loadSession() async {
    final storedToken = await _storage.read(key: _keyToken);
    final storedUserId = await _storage.read(key: _keyUserId);

    if (storedToken != null && storedUserId != null) {
      token = storedToken;
      userId = int.tryParse(storedUserId);
      return true;
    }

    return false;
  }

  /// Clear session (logout)
  static Future<void> clearSession() async {
    token = null;
    userId = null;

    await _storage.deleteAll();
  }
}