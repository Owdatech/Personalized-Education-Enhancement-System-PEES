import 'dart:convert';

import 'package:pees/Models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreferencesKeys {
  loginUser,
  language,
}

class PreferencesManager {
  SharedPreferences? prefs;
  static PreferencesManager shared = PreferencesManager();

  PreferencesManager() {
    setup();
  }

  setup() async {
    prefs = await SharedPreferences.getInstance();
  }

  setLanguage(String langName) {
    prefs?.setString(PreferencesKeys.language.name, langName);
    // print("Set Language : $langName");
  }

  getLanguage() {
    String? name = prefs?.getString(PreferencesKeys.language.name) ?? 'en';
    // print("get Language : $name");
    return name;
  }

  removeLanguage() {
    prefs?.remove(PreferencesKeys.language.name);
    // print("Remove Language");
  }

  logout() async {
    await prefs?.remove(PreferencesKeys.loginUser.name);
  }

  saveUser(AIUser user) {
    String strUser = jsonEncode(user.toJson());
    prefs?.setString(PreferencesKeys.loginUser.name, strUser);
  }

  getUser() async {
    String? name = prefs?.getString(PreferencesKeys.loginUser.name);
    return name;
  }

  Future<AIUser?> loadUser() async {
    prefs = await SharedPreferences.getInstance();
    String? strUser = prefs?.getString(PreferencesKeys.loginUser.name);
    if (strUser != null && strUser != '') {
      Map<String, dynamic> dict = jsonDecode(strUser);
      AIUser user = AIUser.fromJson(dict);
      AIUser.shared = user;
      return user;
    } else {
      return null;
    }
  }

  Future<void> saveCredentials(String token, String userId, String role,
      String jwtToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('role', role);
    await prefs.setString('jwtToken', jwtToken);
    await prefs.setString('refreshToken', refreshToken);
    print("User Details saved.");
  }

  Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');
    final role = prefs.getString('role');
    final jwtToken = prefs.getString('jwtToken');
    final refreshToken = prefs.getString('refreshToken');

    if (token != null &&
        userId != null &&
        role != null &&
        jwtToken != null &&
        refreshToken != null) {
      return {
        'token': token,
        'userId': userId,
        'role': role,
        'jwtToken': jwtToken,
        'refreshToken': refreshToken
      };
    }
    return null;
  }
}
