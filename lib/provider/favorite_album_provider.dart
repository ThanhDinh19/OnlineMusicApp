import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FavoriteAlbumProvider with ChangeNotifier {
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> get albums => _albums;

  Future<void> loadAlbumFavorites(String userId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/album/get_favorite_albums.php?user_id=$userId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data["status"] == true) {
        _albums = List<Map<String, dynamic>>.from(data["favorites"]);
        notifyListeners();
      }
    }
  }

  Future<void> toggleAlbumFavorite(String userId, String albumId, bool isFav) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/album/add_favorite_album.php");
    await http.post(url, body: {
      "user_id": userId,
      "album_id": albumId,
      "action": isFav ? "add" : "remove"
    });

    // Cập nhật cục bộ (giúp refresh ngay lập tức mà không reload API)
    if (isFav) {
      // Tự thêm tạm album mới (cần load lại nếu muốn chính xác)
    } else {
      _albums.removeWhere((a) => a["album_id"].toString() == albumId);
    }
    notifyListeners();
  }

}
