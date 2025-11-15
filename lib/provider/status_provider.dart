import 'package:flutter/cupertino.dart';

class StatusProvider extends ChangeNotifier {
  Map<int, bool> appBarState = {
    0: true,
    1: true,
    2: true,
    3: true,
  };

  void setAppBar(int tab, bool value) {
    appBarState[tab] = value;
    notifyListeners();
  }

  bool getAppBar(int tab) => appBarState[tab] ?? true;
}
