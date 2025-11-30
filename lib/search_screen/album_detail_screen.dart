import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../design/EqualizerAnimation.dart';
import '../function/handle_framework.dart';
import '../home_screens/mini_player.dart';
import '../premium_screen/PremiumBottomSheet.dart';
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
    fetchOnlineSongs();
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

  // thêm vào danh sách phát
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

  // lấy danh sách nhạc internet (all)
  List<Map<String, dynamic>> onlineSongs = [];
  Future<List<Map<String, dynamic>>> fetchOnlineSongs() async {
    try {
      final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/song/get_songs.php");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse["status"] == true && jsonResponse["songs"] != null) {
          final List songs = jsonResponse["songs"];

          setState(() {
            onlineSongs = List<Map<String, dynamic>>.from(songs);
          });

          print("Tải thành công ${songs.length} bài hát");
          return onlineSongs;
        } else {
          print("API trả về không có danh sách bài hát");
        }
      } else {
        print("Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi khi tải danh sách bài hát: $e");
    }

    return [];
  }
  List<Map<String, dynamic>> onlinePlaylists = [];
  Future<void> getUserPlaylists() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    final uId = userProvider!.id.toString();
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/get_user_playlists.php?user_id=$uId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        setState(() {
          onlinePlaylists = List<Map<String, dynamic>>.from(data["playlists"]);
        });
      }
    }
  }
  List<bool> selectedPlaylists = [];
  void addSongToPlaylist(String song_id) {
    String songId = song_id;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (selectedPlaylists.length != onlinePlaylists.length) {
              selectedPlaylists = List.generate(onlinePlaylists.length, (_) => false);
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color:  Color(0xFF1E201E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // đóng bottom sheet
                                Navigator.pop(context); // đóng luôn trang hiện tại
                              },
                              child: const Text('Hủy',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const Text(
                              'Thêm vào playlist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Xử lý khi nhấn “Xong”

                                // khởi tạo một arr id của playlist đc chọn
                                List<int> selectedPlaylistIds = [
                                  for (int i = 0; i < onlinePlaylists.length; i++)
                                    if (selectedPlaylists[i]) onlinePlaylists[i]["playlist_id"]
                                ];

                                if(songId != null && songId.isNotEmpty && selectedPlaylistIds.isNotEmpty){
                                  saveSongToPlaylists(songId, selectedPlaylistIds);
                                  showToast("Đã thêm bài hát vào playlist");
                                }

                                print("Playlist được chọn: $selectedPlaylistIds");

                                Navigator.pop(context);
                              },
                              child: const Text('Xong',
                                  style: TextStyle(color: Colors.lightGreen)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Nút tạo playlist mới
                      ElevatedButton.icon(
                        onPressed: () async {
                          final created = await createNewPlaylist(context);

                          if (created) {
                            await getUserPlaylists();

                            // cập nhật lại checkbox cho đúng số lượng playlist
                            setState(() {
                              selectedPlaylists = List.generate(onlinePlaylists.length, (_) => false);
                            });
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Tạo playlist mới',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black38,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),


                      const SizedBox(height: 20),

                      // Danh sách playlist có thể cuộn
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: onlinePlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = onlinePlaylists[index];
                            final songs = playlist["songs"] ?? [];
                            final songCount = playlist["song_count"];

                            Widget leadingWidget;
                            if (songs.length >= 4) {
                              leadingWidget = ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade800,
                                  child: GridView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 1,
                                      crossAxisSpacing: 1,
                                    ),
                                    itemCount: 4,
                                    itemBuilder: (context, i) {
                                      final song = songs[i];
                                      return Image.network(
                                        song["cover"] ?? "",
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: Colors.grey.shade700),
                                      );
                                    },
                                  ),
                                ),
                              );
                            } else if (songs.isNotEmpty) {
                              leadingWidget = ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  songs[0]["cover"] ?? "",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: Colors.grey.shade700),
                                ),
                              );
                            } else {
                              leadingWidget = ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.library_music, color: Colors.white54),
                                ),
                              );
                            }


                            return ListTile(
                              leading: leadingWidget,
                              title: Text(
                                playlist["name"].toString(),
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                "${int.parse(songCount.toString())} bài hát",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Checkbox(
                                value: selectedPlaylists[index],
                                activeColor: Colors.blueAccent,
                                checkColor: Colors.white,
                                shape: const CircleBorder(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedPlaylists[index] = value!;
                                    print(selectedPlaylists);
                                    print(playlist["playlist_id"]);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  Future<void> saveSongToPlaylists(String songId, List<int> playlistIds) async {
    final url = Uri.parse(
      "http://10.0.2.2:8081/music_API/online_music/playlist/add_song_to_playlists.php",
    );

    final response = await http.post(
      url,
      body: {
        "song_id": songId,
        "playlist_ids": jsonEncode(playlistIds),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Kết quả: $data");
    } else {
      print("Lỗi HTTP: ${response.statusCode}");
    }
  }
  Future<bool> createNewPlaylist(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final controller = TextEditingController();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // ko tắt dialog
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Tạo playlist mới",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Tên playlist",
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text("Hủy", style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            Fluttertoast.showToast(msg: "Vui lòng nhập tên playlist");
                            return;
                          }

                          /// 🔹 Loading root navigator (không nằm trong bottomsheet)
                          showDialog(
                            context: dialogContext,
                            useRootNavigator: true,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(color: Colors.blueAccent),
                            ),
                          );

                          try {
                            final res = await http.post(
                              Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/create_playlist.php"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({
                                "user_id": user!.id.toString(),
                                "name": name,
                              }),
                            );

                            Navigator.of(dialogContext, rootNavigator: true).pop();

                            final data = jsonDecode(res.body);

                            if (data["status"] == "success") {
                              showToast("Đã tạo playlist");
                              Navigator.pop(dialogContext, true); // ✔ trả về true
                            } else {
                              Fluttertoast.showToast(msg: "Lỗi tạo playlist");
                            }
                          } catch (e) {
                            Navigator.of(dialogContext, rootNavigator: true).pop();
                            showToast("Lỗi kết nối");
                          }
                        },
                        child: const Text("Tạo"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  // tải xuống
  bool isDownloading = false;
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
  Future<void> downloadSong(String songId, String title, String audioUrl, String artist, String coverUrl) async {
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.user?.id ?? "";
    final audioProvider = Provider.of<AudioPlayerProvider>(context);

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
                  final songId = song["song_id"].toString() ?? "";
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
                    title: Row(
                      children: [
                        if (audioProvider.currentIndex == index && audioProvider.playlistId == "Album${widget.albumId.toString()}") ...[
                          const SizedBox(width: 2),
                          if(audioProvider.isPlaying)...[
                            EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                            const SizedBox.shrink(),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                songTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFE700),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ]
                          else ...[
                            const SizedBox.shrink(),
                            Expanded(
                              child: Text(
                                songTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ]else...[
                          Expanded(
                            child: Text(
                              songTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      songArtist,
                      style: const TextStyle(color: Colors.white70),
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
                                    color: Color(0xFF1E201E),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
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
                                            child: const Icon(Icons.music_note, color: Colors.white54),
                                          ),
                                        ),
                                        title: Text(songTitle),
                                        subtitle: Text(songArtist),
                                      ),

                                      const Divider(color: Colors.white24),

                                      ListTile(
                                        leading: const Icon(Icons.share),
                                        title: const Text('Chia sẻ'),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.remove_circle_outline),
                                        title: const Text('Thêm vào playlist'),
                                        onTap: () async {
                                          await getUserPlaylists();
                                          setState(() {});
                                          selectedPlaylists = [];
                                          addSongToPlaylist(songId);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.remove_circle_outline),
                                        title: const Text('Tải xuống'),
                                          onTap: () async {
                                            if (isDownloading) return; // chặn spam
                                            setState(() => isDownloading = true);

                                            await downloadSong(songId, songTitle, audioUrl, songArtist, coverUrl);

                                            setState(() => isDownloading = false);
                                          }
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

                    onTap: () async {

                      final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

                      // Gọi API để lấy toàn bộ danh sách
                      List<Map<String, dynamic>> songsList = songs;

                      // Set playlist & bài hiện tại
                      await audioProvider.setPlaylist(songsList, startIndex: index,);

                      audioProvider.setCurrentSong(index);
                      audioProvider.setPlaying(true);
                      audioProvider.setPlaylistId("Album${widget.albumId.toString()}");

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
