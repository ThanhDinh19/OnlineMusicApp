import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';

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


  // load playlist
  Future<void> getUserPlaylists(String userId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/get_user_playlists.php?user_id=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        _playlists = List<Map<String, dynamic>>.from(data["playlists"]);
        notifyListeners();
      }
    }
  }
  // rename tên playlist
  Future<bool> updatePlaylistName(String userId, String playlistId, String newName) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/update_playlist_name.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "playlist_id": playlistId,
          "new_name": newName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          print("Playlist updated successfully!");
          return true;
        } else {
          print("${data["message"]}");
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating playlist name: $e");
    }
    return false;
  }

  Future<bool> deletePlaylist(String userId, String playlistId) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/playlist/delete_playlist.php");

    final response = await http.post(
      url,
      body: {
        "user_id": userId,
        "playlist_id": playlistId,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        return true;
      } else {
        debugPrint("${data["message"]}");
      }
    } else {
      debugPrint("HTTP Error: ${response.statusCode}");
    }

    return false;
  }

}