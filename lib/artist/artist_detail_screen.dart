import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../home_screens/mini_player.dart';
import '../provider/audio_player_provider.dart';
import '../home_screens/just_audio_demo.dart';
import 'package:page_transition/page_transition.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;

  const ArtistDetailScreen({
    required this.artistId,
    super.key,
  });

  @override
  ArtistDetailScreenState createState() =>ArtistDetailScreenState();
}

class ArtistDetailScreenState extends State<ArtistDetailScreen> {
  bool hasChangedFavorite = false;
  bool isFavorite = false;
  int? currentIndex;
  String avatarUrl = '';
  String artistName = '';

  @override
  void initState() {
    super.initState();
    fetchSongsByArtist(widget.artistId.toString());
  }

  List<Map<String, dynamic>> artistSongs = [];
  Future<void> fetchSongsByArtist(String artistId) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/artist/get_songs_by_artist.php");

    final response = await http.post(url, body: {
      "artist_id": artistId,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        setState(() {
          artistSongs = List<Map<String, dynamic>>.from(data["songs"]);
          avatarUrl = data["avatar_url"] ?? "";
          artistName = data["artist_name"] ?? "";
        });
      }
    }
  }

  void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black.withOpacity(0.7),
      textColor: Colors.white,
      fontSize: 16,
    );

    // Tuỳ chọn: tự tắt sớm hơn (nếu muốn)
    Future.delayed(const Duration(seconds: 1), () {
      Fluttertoast.cancel();
    });
  }

  Future<void> toggleFavoriteAlbum(String userId, String albumId, bool isFav) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/album/add_favorite_album.php");
    final response = await http.post(url, body: {
      "user_id": userId,
      "album_id": albumId,
      "action": isFav ? "add" : "remove"
    });

    print(response.body);
  }

  Future<void> checkFavoriteStatus(String userId, String albumId) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/album/check_favorite_album.php?user_id=$userId&album_id=$albumId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == true && data["is_favorite"] == true) {
          setState(() {
            isFavorite = true;
          });
        } else {
          setState(() {
            isFavorite = false;
          });
        }
      }
    } catch (e) {
      print("Lỗi khi kiểm tra yêu thích: $e");
    }
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header (ảnh + tên nghệ sĩ)
            Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(avatarUrl.toString()),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF0F0F1C),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 55,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          artistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          size: 30,
                        ),
                        onPressed: () async {
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white24),

            //  Danh sách bài hát
            Expanded(
              child: artistSongs.isEmpty
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                itemCount: artistSongs.length,
                itemBuilder: (context, index) {
                  final song = artistSongs[index];
                  final songTitle = song["title"] ?? "";
                  final playCount = song["play_count"] ?? "";
                  final coverUrl = song["cover_url"] ?? "";
                  final audioUrl = song["audio_url"] ?? "";
                    print(artistSongs);
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        coverUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    title: Text(
                      songTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      playCount.toString(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.more_horiz, color: Colors.white70),

                    onTap: () async {

                      final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

                      // Gọi API để lấy toàn bộ danh sách
                      List<Map<String, dynamic>> songsList = artistSongs;

                      // Set playlist & bài hiện tại
                      await audioProvider.setPlaylist(songsList, startIndex: index,);


                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.bottomToTop,
                              child: const JustAudioDemo(),
                            ),
                          );
                          print("currentSongPath: ${audioProvider.currentSongPath}");
                        },
                        child: MiniPlayer(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
