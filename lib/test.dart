import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SongPlayer extends StatefulWidget {
  @override
  _SongPlayerState createState() => _SongPlayerState();
}

class _SongPlayerState extends State<SongPlayer> {
  final player = AudioPlayer();
  List songs = [];
  bool isLoading = true;
  int? currentIndex; // để biết bài nào đang phát

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  /// 📦 Load danh sách bài hát từ PHP server
  Future<void> loadSongs() async {
    try {
      final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/list_songs_android.php");
      final response = await http.get(url);

      print("HTTP status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        print("----------------------------------- ${data}");
        setState(() {
          songs = data;
          isLoading = false;
        });
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi khi tải danh sách: $e");
    }
  }

  /// 🎵 Phát bài hát theo tên file
  Future<void> playSong(String url, int index) async {
    print("🔗 Đang phát: $url");

    try {
      await player.setUrl(url);
      await player.play();

      setState(() {
        currentIndex = index;
      });
    } catch (e) {
      print("Lỗi khi phát bài: $e");
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🎶 My Music Server")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final title = song["title"] ?? "Unknown Title";
          final artist = song["artist"] ?? "Unknown Artist";
          final fileUrl = song["url"] ?? "";
          final coverUrl = song["cover"] ?? "";

          return ListTile(
            leading: coverUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                coverUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Nếu load ảnh lỗi, hiển thị icon nhạc
                  return Icon(
                    currentIndex == index
                        ? Icons.play_circle_fill
                        : Icons.music_note,
                    color: currentIndex == index ? Colors.green : null,
                    size: 40,
                  );
                },
              ),
            )
                : Icon(
              currentIndex == index
                  ? Icons.play_circle_fill
                  : Icons.music_note,
              color: currentIndex == index ? Colors.green : null,
              size: 40,
            ),
            title: Text(title),
            subtitle: Text(artist),
            onTap: () => playSong(fileUrl, index),
          );
        },
      ),
    );
  }

}
