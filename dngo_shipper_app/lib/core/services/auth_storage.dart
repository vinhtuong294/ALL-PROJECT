import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _roleKey = 'role';
  static const _walletIdKey = 'wallet_id';
  static const _shipperIdKey = 'shipper_id';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['user_id'] != null) await prefs.setString(_userIdKey, data['user_id']);
    if (data['user_name'] != null) await prefs.setString(_userNameKey, data['user_name']);
    if (data['role'] != null) await prefs.setString(_roleKey, data['role']);
    if (data['wallet_id'] != null) await prefs.setString(_walletIdKey, data['wallet_id']);
    if (data['shipper_id'] != null) await prefs.setString(_shipperIdKey, data['shipper_id']);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString(_userIdKey),
      'user_name': prefs.getString(_userNameKey),
      'role': prefs.getString(_roleKey),
      'wallet_id': prefs.getString(_walletIdKey),
      'shipper_id': prefs.getString(_shipperIdKey),
    };
  }

  static Future<String?> getWalletId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_walletIdKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_walletIdKey);
    await prefs.remove(_shipperIdKey);
  }
}
