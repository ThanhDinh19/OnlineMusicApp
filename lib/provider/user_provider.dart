import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_model.dart';


class UserProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

}


  // Future<void> loadUserFromPrefs() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final userData = prefs.getString('user');
  //   if (userData != null) {
  //     _user = UserModel.fromJson(json.decode(userData));
  //     notifyListeners();
  //   }
  // }

  // Future<void> _saveUserToPrefs(UserModel user) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('user', json.encode(user.toJson()));
  // }

