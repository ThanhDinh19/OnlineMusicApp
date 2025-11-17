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
    // Đảm bảo notifyListeners chạy ngoài phase build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Có thể kiểm tra mounted nếu bạn giữ provider stateful wrapper, nhưng provider thường ổn.
      try {
        notifyListeners();
      } catch (_) {}
    });
  }

  bool getAppBar(int tab) => appBarState[tab] ?? true;
}
