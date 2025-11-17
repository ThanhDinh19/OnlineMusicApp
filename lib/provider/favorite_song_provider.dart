import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class FavoriteSongProvider extends ChangeNotifier{
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> get songs => _songs;

  Future<void> loadSongFavorites(String userId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/song/get_favorite_songs.php?user_id=$userId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data["status"] == "success") {
        _songs = List<Map<String, dynamic>>.from(data["favorite_songs"]);
        notifyListeners();
      }
    }
  }

  Future<void> toggleSongFavorite(String userId, String songId, bool isFav) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/song/favorite_song.php");
    final res = await http.post(url, body: {
      "user_id": userId,
      "song_id": songId,
      "action": isFav ? "add" : "remove"
    });
    print("userID: ${userId}, songId: ${songId}, fav ${isFav}");
    print(res.body);
    // Cập nhật cục bộ (giúp refresh ngay lập tức mà không reload API)
    if (isFav) {
      // Tự thêm tạm songs mới (cần load lại nếu muốn chính xác)
    } else {
      _songs.removeWhere((a) => a["song_id"].toString() == songId);
    }
    notifyListeners();
  }
}