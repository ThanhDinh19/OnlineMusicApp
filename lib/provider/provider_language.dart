import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _lang = "vi"; // mặc định tiếng Việt

  String get lang => _lang;

  void toggleLanguage() {
    _lang = _lang == "vi" ? "en" : "vi";
    notifyListeners();
  }

  void setLanguage(String langCode) {
    _lang = langCode;
    notifyListeners();
  }
}
