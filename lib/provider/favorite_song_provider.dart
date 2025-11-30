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

  Future<void> toggleSongFavorite(
      String userId, String songId, bool isFav, Map<String, dynamic> songData) async {

    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/song/favorite_song.php");

    await http.post(url, body: {
      "user_id": userId,
      "song_id": songId,
      "action": isFav ? "add" : "remove"
    });

    if (isFav) {
      //  Tự thêm vào list local ngay lập tức
      _songs.insert(0, songData);
    } else {
      // Remove ngay lập tức
      _songs.removeWhere((s) => s["song_id"].toString() == songId);
    }

    notifyListeners();
  }

}