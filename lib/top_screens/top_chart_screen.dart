import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/function/handle_framework.dart';
import 'package:music_app/premium_screen/premium_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../home_screens/just_audio_demo.dart';
import '../home_screens/mini_player.dart';
import '../premium_screen/PremiumBottomSheet.dart';
import '../provider/audio_player_provider.dart';
import '../provider/user_provider.dart';

class TopChartScreen extends StatefulWidget{
  @override
  TopChartScreenState createState() => TopChartScreenState();
}

class TopChartScreenState extends State<TopChartScreen> {
  List<Map<String, dynamic>> topSongs = [];
  bool loading = true;
  final player = AudioPlayer();
  int? currentIndex; // để biết bài nào đang phát

  final String dateNow = DateFormat("dd 'tháng' MM, yyyy").format(
      DateTime.now());


  @override
  void initState() {
    super.initState();
    fetchTopSongs();
  }

  Future<dynamic> showMessage(String _msg) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(_msg),
          actions: <Widget>[
            TextButton(
              child: new Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // hiển thị khi thêm song vào playlist thành công
  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
      // vị trí giữa màn hình
      backgroundColor: Colors.black45.withOpacity(0.6),
      // màu nền
      textColor: Colors.white,
      // màu chữ
      fontSize: 16.0, // cỡ chữ
    );

    Future.delayed(Duration(seconds: 1), () {
      Fluttertoast.cancel(); // ẩn thủ công sau 1 giây
    });
  }

  Future<String> downloadSong(String fileUrl, String fileName) async {
    final dir = await getApplicationDocumentsDirectory(); // thư mục local app
    final filePath = '${dir.path}/$fileName.mp3';

    try {
      await Dio().download(fileUrl, filePath);
      print("Tải thành công: $filePath");
      return filePath;
    } catch (e) {
      print("Lỗi tải nhạc: $e");
      return "";
    }
  }

  Future<void> saveDownloadedSongToDB(String userId, String songId, String title, String artist, String coverUrl, int duration, String audioUrl,) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        showToast("Vui lòng đăng nhập để tải xuống");
        return;
      }

      final Map<String, dynamic> songData = {
        "user_id": int.parse(userId.toString()),
        "song_id": int.parse(songId.toString()),
        "title": title,
        "artist": artist,
        "cover_url": coverUrl,
        "duration": duration,
        "mp3_url": audioUrl,
      };

      final response = await http.post(
        Uri.parse(
            "http://10.0.2.2:8081/music_API/online_music/download/save_downloaded_song.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(songData),
      );

      final result = jsonDecode(response.body);
      if (result["status"] == "success") {
        showToast("${result["message"]}");
      } else {
        showToast(result["message"] ?? "Không thể tải xuống");
      }
    } catch (e) {
      debugPrint("Lỗi tải xuống: $e");
      showToast("Lỗi khi tải xuống");
    }
  }

  // Future<String?> downloadSongFile(String songUrl, String fileName) async {
  //   try {
  //     final dir = await getApplicationDocumentsDirectory();
  //     final audioDir = Directory('${dir.path}/audio');
  //     if (!audioDir.existsSync()) audioDir.createSync(recursive: true);
  //
  //     final filePath = '${audioDir.path}/$fileName.mp3';
  //     await Dio().download(songUrl, filePath);
  //
  //     print("Đã tải: $filePath");
  //     return filePath; // trả về local path để lưu DB
  //   } catch (e) {
  //     print("Lỗi tải file: $e");
  //     return null;
  //   }
  // }

  // lấy toàn bộ nhạc
  Future<void> fetchTopSongs() async {
    const String url =
        "http://10.0.2.2:8081/music_API/online_music/song/get_top_songs.php";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == "success") {
          setState(() {
            topSongs = List<Map<String, dynamic>>.from(data["songs"]);
            loading = false;
          });
        }
      } else {
        debugPrint("❌ HTTP Error: ${res.statusCode}");
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("❌ Error loading songs: $e");
      setState(() => loading = false);
    }
  }

  // đếm số lượng nhạc được nghe
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
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(
        context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1C),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD61C4E), Color(0xFF1A1A2F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // banner
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ Color(0xFFFF6464), Color(0xFFFF9D23)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrangeAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.local_fire_department, color: Colors.white,
                          size: 26),
                      Expanded(
                        child: Text(
                          'Top các bài hát phổ biến hiện nay',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Text(
                "Cập nhật: $dateNow",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 10),
              _buildHotList(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotList(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topSongs.length,
      itemBuilder: (context, index) {
        final song = topSongs[index];
        final songId = song["song_id"] ?? "";
        final title = song["title"] ?? "Unknown Title";
        final artist = song["artist"] ?? "Unknown Artist";
        final audioUrl = song["audio_url"] ?? "";
        final duration = song["duration"] ?? "";
        final coverUrl = song["cover_url"] ?? "";

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
                return Icon(
                  currentIndex == index
                      ? Icons.play_circle_fill
                      : Icons.music_note,
                  color:
                  currentIndex == index ? Colors.green : null,
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
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle:
          Text(
            artist,
            style: const TextStyle(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) {
                  return DraggableScrollableSheet(

                    initialChildSize: 0.6,
                    minChildSize: 0.1,
                    maxChildSize: 0.9,
                    expand: false,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F0F1C),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(15)),
                        ),
                        child: ListView(
                          controller: scrollController,
                          children: [
                            ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: coverUrl.isNotEmpty
                                    ? Image.network(
                                  coverUrl,
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                )
                                    : Container(
                                  width: 55,
                                  height: 55,
                                  color: Colors.grey.shade800,
                                  child: const Icon(
                                      Icons.music_note, color: Colors.white54),
                                ),
                              ),
                              title: Text(title),
                              subtitle: Text(artist),
                            ),

                            const Divider(color: Colors.white24),

                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text('Chia sẻ'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline),
                              title: const Text('Thêm vào danh sách phát'),
                              onTap: () async {
                                // await loadPlaylists();
                                // setState(() {});
                                // selectedPlaylists = [];
                                // addSongToPlaylist(songId);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.download),
                              title: Text('Tải xuống'),
                              onTap: () async {

                                HandleFramework hf = HandleFramework();
                                bool checkPremium = await hf.checkPremiumStatus();
                                if(checkPremium == true)
                                {
                                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                                  final userId = userProvider.user?.id;

                                  final fileName = "${songId}_${title.replaceAll(' ', '_')}";

                                  // Bước 1: Kiểm tra file đã tồn tại chưa
                                  final existingPath = await checkIfSongExists(fileName);

                                  String? filePath;

                                  if (existingPath != null) {
                                    // Nếu đã tồn tại – không tải lại
                                    filePath = existingPath;
                                    showToast("Bài hát đã được tải trước đó");
                                  } else {
                                    // Nếu chưa có – tải mới
                                    filePath = await downloadSongFile(audioUrl, fileName);
                                  }

                                  if (filePath != null) {
                                    // Lưu xuống MySQL (bạn đã làm đúng)
                                    final body = {
                                      "user_id": userId.toString(),
                                      "song_id": songId.toString(),
                                      "title": title,
                                      "artist": artist,
                                      "cover_url": coverUrl,
                                      "duration": "0",
                                      "audio_url": filePath,
                                    };

                                    final response = await http.post(
                                      Uri.parse("http://10.0.2.2:8081/music_API/online_music/download/save_downloaded_song.php"),
                                      headers: {"Content-Type": "application/json"},
                                      body: jsonEncode(body),
                                    );

                                    final result = jsonDecode(response.body);

                                    if (result["status"] == "success") {
                                      showToast(existingPath != null ? "Đã có trong thư viện" : "Tải xuống thành công");
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: "Lưu thất bại: ${result["message"]}",
                                        backgroundColor: Colors.red,
                                      );
                                    }
                                  }
                                  Navigator.pop(context);
                                }
                                else {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => const PremiumBottomSheet(),
                                  );
                                }
                              },

                            ),
                            const ListTile(
                              leading: Icon(Icons.access_time),
                              title: Text('Hẹn giờ'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          // phát nhạc
          onTap: () async {
            final audioProvider = Provider.of<AudioPlayerProvider>(
                context, listen: false);

            // Gọi API để lấy toàn bộ danh sách
            List<Map<String, dynamic>> songsList = topSongs;

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
    );
  }

  Future<String?> checkIfSongExists(String fileName) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory musicDir = Directory("${appDir.path}/MusicApp/downloads");

    final String filePath = "${musicDir.path}/$fileName.mp3";

    final File file = File(filePath);

    if (await file.exists()) {
      return filePath; // Trả về đường dẫn nếu file có tồn tại
    } else {
      return null; // Chưa tồn tại
    }
  }

  Future<String?> downloadSongFile(String url, String fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory musicDir = Directory("${appDir.path}/MusicApp/downloads");

      if (!(await musicDir.exists())) {
        await musicDir.create(recursive: true);
      }

      final String filePath = "${musicDir.path}/$fileName.mp3";

      // 🔍 Kiểm tra nếu file đã tồn tại
      final File existingFile = File(filePath);
      if (await existingFile.exists()) {
        print("File already exists: $filePath");
        return filePath; // Không tải nữa
      }

      // Tải file từ URL
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        print("Download failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error downloading file: $e");
      return null;
    }
  }


}