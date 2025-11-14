import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_model.dart';


class StatusProvider with ChangeNotifier {

  bool showAppBar = true;

  void toggleAppBar(bool show) {
    showAppBar = show;
    notifyListeners();
  }
}