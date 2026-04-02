import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken = "token";
  static const _keyUserId = "userId";

  /// Save login
  static Future<void> saveUser(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, userId);
  }

  /// Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Get userId
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Check login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}