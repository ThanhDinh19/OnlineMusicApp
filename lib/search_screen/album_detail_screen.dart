import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../home_screens/mini_player.dart';
import '../provider/audio_player_provider.dart';
import '../provider/favorite_album_provider.dart';
import '../provider/user_provider.dart';
import '../home_screens/just_audio_demo.dart';
import 'package:page_transition/page_transition.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  final String albumName;
  final String albumCover;

  const AlbumDetailScreen({
    required this.albumId,
    required this.albumName,
    required this.albumCover,
    super.key,
  });

  @override
  _AlbumDetailScreenState createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  bool hasChangedFavorite = false;
  bool isFavorite = false;
  List<Map<String, dynamic>> songs = [];
  int? currentIndex;

  @override
  void initState() {
    super.initState();
    // kiểm tra trạng thái favorite album
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? "";

    if (userId.isNotEmpty) {
      checkFavoriteStatus(userId, widget.albumId);
      hasChangedFavorite = false; // ban đầu chưa thay đổi gì
    }

    // load danh sách nhạc của album
    loadSongs();
  }

  Future<void> loadSongs() async {
    final url =
        "http://10.0.2.2:8081/music_API/online_music/album/get_album_songs.php?id=${widget.albumId}";
    print("Fetching songs from: $url");

    try {
      final res = await http.get(Uri.parse(url));
      print("Status: ${res.statusCode}");
      print("Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data is List) {
          setState(() {
            songs = List<Map<String, dynamic>>.from(data);
          });
        } else if (data is Map && data.containsKey("error")) {
          print("Lỗi API: ${data['error']}");
        } else {
          print("Dữ liệu không đúng dạng List");
        }
      } else {
        print("HTTP lỗi: ${res.statusCode}");
      }
    } catch (e) {
      print("Lỗi khi load bài hát: $e");
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

  Future<void> increasePlayCount(String songId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/song/update_play_count.php");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"song_id": songId}),
      );

      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        print("🎧 Play count updated: ${data["play_count"]}");
      } else {
        print("⚠️ Lỗi cập nhật lượt nghe: ${data["message"]}");
      }
    } catch (e) {
      print("Lỗi khi gọi API: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.user?.id ?? "";

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Header (ảnh + tên album)
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.albumCover),
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
                    onPressed: () => Navigator.pop(context, hasChangedFavorite),
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
                          widget.albumName,
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

                          final favProvider = Provider.of<FavoriteAlbumProvider>(context, listen: false);
                          await favProvider.toggleAlbumFavorite(userId, widget.albumId, isFavorite);

                          showToast(isFavorite
                              ? "Đã thêm vào yêu thích"
                              : "Đã xóa khỏi yêu thích");
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white24),

            // 🔹 Danh sách bài hát
            Expanded(
              child: songs.isEmpty
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final songTitle = song["title"] ?? "";
                  final songArtist = song["artist"] ?? "";
                  final coverUrl = song["cover_url"] ?? "";
                  final audioUrl = song["audio_url"] ?? "";

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
                      songArtist,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.more_horiz, color: Colors.white70),

                    onTap: () async {

                      final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

                      // Gọi API để lấy toàn bộ danh sách
                      List<Map<String, dynamic>> songsList = songs;

                      // Set playlist & bài hiện tại
                      await audioProvider.setPlaylist(songsList, startIndex: index,);

                      await increasePlayCount(audioProvider.currentSongId.toString());

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
