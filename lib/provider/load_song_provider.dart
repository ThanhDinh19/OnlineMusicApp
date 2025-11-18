import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class LoadSongProvider extends ChangeNotifier{
  List<Map<String, dynamic>> _downloadedSongs = [];
  List<Map<String, dynamic>> get downloadedSongs => _downloadedSongs;

  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> get playlists => _playlists;

  // load downloaded songs
  Future<List<Map<String, dynamic>>> fetchOfflineSongs(String userId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/download/get_downloaded_songs.php?user_id=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        return List<Map<String, dynamic>>.from(data["songs"]);
      }
    }
    return [];
  }
  Future<void> loadDownloadedSongs(String userId) async {
    final songs = await fetchOfflineSongs(userId);
    _downloadedSongs = songs;
    notifyListeners();
  }
}