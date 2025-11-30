import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FollowArtistProvider with ChangeNotifier{

  Future<void> toggleFollowArtist(String userId, String artistId, bool isFollowing) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/artist/follow_artist.php");

    final response = await http.post(url, body: {
      "user_id": userId,
      "artist_id": artistId,
      "action": isFollowing ? "follow" :  "unfollow"
    });

    final data = jsonDecode(response.body);
    print(data);

    if (data["status"] == "success") {

    }
    notifyListeners();
  }
}