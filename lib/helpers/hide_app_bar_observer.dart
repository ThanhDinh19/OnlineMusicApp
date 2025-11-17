import 'package:flutter/cupertino.dart';

class HideAppBarObserver extends NavigatorObserver {
  final int tabIndex;
  final Function(int, bool) onToggle;

  HideAppBarObserver(this.tabIndex, this.onToggle);

  void _handle(Route? route) {
    if (route == null) return;

    final name = route.settings.name ?? "";

    // Tất cả những màn cần ẩn AppBar
    const hideScreens = {
      "artist_detail",
      "search",
      "voice",
      "albumScreen",
      "genre_detail",
      "playlistDetail",
    };

    if (hideScreens.contains(name)) {
      onToggle(tabIndex, false); // Ẩn
    } else {
      onToggle(tabIndex, true); // Hiện
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) => _handle(route);

  @override
  void didPop(Route route, Route? previousRoute) => _handle(previousRoute);
}
