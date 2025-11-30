// have been used
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/artist/artist_detail_screen.dart';
import 'package:music_app/genre/genre_detail_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../design/EqualizerAnimation.dart';
import '../function/handle_framework.dart';
import '../premium_screen/PremiumBottomSheet.dart';
import '../provider/audio_player_provider.dart';
import '../provider/status_provider.dart';
import '../provider/user_provider.dart';
import '../search_screen/album_detail_screen.dart';
import 'just_audio_demo.dart';
import 'mini_player.dart';

class DiscoverScreen extends StatefulWidget{
  const DiscoverScreen({Key? key}) : super(key: key);
  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {

  List<dynamic> albums = [];
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        fetchAlbums(),
        fetchStarterSongs(),
        fetchRecommendedSongs(),
        fetchRecentAlbums(),
        fetchTopArtists(),
        fetchTopArtistsWithBestPLayCountSongs(),
        fetchRecentSongs(),
      ]);
    });
  }

  // lấy những albums có bài hát nghe gần đây
  List<Map<String, dynamic>> recentAlbums = [];
  bool isLoadingRecent = true;
  Future<void> fetchRecentAlbums() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/album/get_recent_albums.php?user_id=$userId");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        setState(() {
          recentAlbums = List<Map<String, dynamic>>.from(data["albums"]);
          isLoadingRecent = false;
        });
      }
    } else {
      debugPrint("Lỗi khi tải recent albums");
    }
  }

  // fetch favorite albums for new account
  Future<void> fetchAlbums() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/artist/get_albums_by_favorite_artists.php?user_id=${user!.id.toString()}");

    final res = await http.get(url);
    debugPrint("Response: ${res.body}");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        setState(() {
          albums = data["albums"];
          isLoading = false;
        });
        print("==========================================================================");
        print(albums);
        debugPrint("Tải ${albums.length} album");
      } else {
        debugPrint("Dữ liệu không hợp lệ: ${data["message"]}");
      }
    } else {
      debugPrint("Lỗi server: ${res.statusCode}");
    }
  }

  List<Map<String, dynamic>> recommendedSongs = [];


  Future<void> fetchRecommendedSongs() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/recommendation/recommendations.php?user_id=$userId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        if (data["recommendations"] == null || data["recommendations"].isEmpty) {
          debugPrint("🟡 Chưa có lịch sử nghe → tải gợi ý cho người mới");
          await fetchStarterSongs();
        } else {
          setState(() {
            recommendedSongs = List<Map<String, dynamic>>.from(data["recommendations"]);
          });
        }
      }
    }
  }

  /// API fallback: Gợi ý cho người mới
  List<Map<String, dynamic>> starterSongs = [];
  Future<void> fetchStarterSongs() async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/recommendation/get_starter_songs.php");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        setState(() {
          starterSongs = List<Map<String, dynamic>>.from(data["songs"]);
        });
      }
    }
  }

  // lấy những nghệ sĩ hay nghe nhất
  List<Map<String, dynamic>> topArtists = [];
  Future<void> fetchTopArtists() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user!.id;

    final url = Uri.parse(
      "http://10.0.2.2:8081/music_API/online_music/history/get_top_artists.php?user_id=$userId",
    );

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data["status"] == "success") {
        setState(() {
          topArtists = List<Map<String, dynamic>>.from(data["artists"]);
        });
      }
    } else {
      debugPrint("Lỗi API lấy top nghệ sĩ: ${res.statusCode}");
    }
  }

  // lấy những nghệ sĩ có bài hát được nghe nhiều nhất
  List<Map<String,dynamic>> bestPLayCountArtists = [];
  Future<void> fetchTopArtistsWithBestPLayCountSongs() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8081/music_API/online_music/artist/get_top_artist_with_max_play_count_songs.php');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            bestPLayCountArtists = List<Map<String, dynamic>>.from(data['artists']);
          });
        } else {
          print('API lỗi');
        }
      } else {
        setState(() {
          print('HTTP ${res.statusCode}');
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // lấy 20 bài hát hay nghe gần đây
  List<Map<String, dynamic>> recentSongs = [];
  Future<void> fetchRecentSongs() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/history/get_recent_songs.php?user_id=$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        setState(() {
          recentSongs = List<Map<String, dynamic>>.from(data["songs"]);
        });
      }
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
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Để bạn bắt đầu
            if(recentAlbums.isEmpty)...[
              const Text(
                'Để bạn bắt đầu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              isLoading ? const Center(child: CircularProgressIndicator(color: Colors.blue)) :
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final item = albums[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12), // bo góc khi click
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumId: item['album_id'].toString(),
                                albumName: item['album_name'],
                                albumCover: item['cover_url'],
                              ),
                              settings: const RouteSettings(name: "albumScreen"),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['cover_url'] ?? '',
                                    width: 130,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Background nửa mờ
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                // Text ở giữa ảnh
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  margin:  EdgeInsets.only(left: 60,top: 90),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: const Text(
                                    'Album',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['album_name'] ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]
            else if(recentAlbums.isNotEmpty)...[
              const Text(
                'Albums có bài bạn nghe gần đây',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentAlbums.length,
                  itemBuilder: (context, index) {
                    final item = recentAlbums[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12), // bo góc khi click
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumId: item['album_id'].toString(),
                                albumName: item['album_name'],
                                albumCover: item['cover_url'],
                              ),
                              settings: const RouteSettings(name: "albumScreen"),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['cover_url'] ?? '',
                                    width: 130,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Background nửa mờ
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                // Text ở giữa ảnh
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  margin:  EdgeInsets.only(left: 60,top: 90),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: const Text(
                                    'Album',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['album_name'] ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],


            const SizedBox(height: 15),

            // Dành riêng cho bạn
            if(recommendedSongs.isEmpty && starterSongs.isNotEmpty)...[
              const Text(
                'Gợi ý cho bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230, // đủ cao để chứa 3 bài (ảnh + text)
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (starterSongs.length / 3).ceil(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, columnIndex) {
                    final start = columnIndex * 3;
                    final end = (start + 3 < starterSongs.length)
                        ? start + 3
                        : starterSongs.length;
                    final columnSongs = starterSongs.sublist(start, end);

                    return Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 330,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(columnSongs.length, (i) {
                          final song = columnSongs[i];
                          final globalIndex = start + i;

                          return Padding(
                            padding: EdgeInsets.zero,
                              child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      song["cover_url"] ?? "",
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ),

                                title: Row(
                                  children: [
                                    if (audioProvider.currentIndex == globalIndex && audioProvider.playlistId == "GoiYChoBan") ...[
                                      const SizedBox(width: 2),
                                      if(audioProvider.isPlaying)...[
                                        EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                                        const SizedBox.shrink(),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            song["title"],
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
                                            song["title"],
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
                                          song["title"],
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
                                    song["artist_name"] ?? "Không rõ nghệ sĩ",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
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
                                                      child: song["cover_url"].isNotEmpty
                                                          ? Image.network(
                                                        song["cover_url"],
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
                                                    title: Text(song["title"]),
                                                    subtitle: Text(song["artist_name"]),
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
                                                      addSongToPlaylist(song["song_id"].toString());
                                                    },
                                                  ),
                                                  ListTile(
                                                      leading: const Icon(Icons.remove_circle_outline),
                                                      title: const Text('Tải xuống'),
                                                      onTap: () async {
                                                        if (isDownloading) return; // chặn spam
                                                        setState(() => isDownloading = true);

                                                        await downloadSong(song["song_id"].toString(), song["title"], song["audio_url"], song["artist_name"], song["cover_url"]);

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
                                  final audioProvider = Provider.of<AudioPlayerProvider>(
                                    context,
                                    listen: false,
                                  );

                                  await audioProvider.setPlaylist(starterSongs, startIndex: globalIndex,);
                                  audioProvider.setCurrentSong(globalIndex);
                                  audioProvider.setPlaying(true);
                                  audioProvider.setPlaylistId("GoiYChoBan");

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
                              ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ]
            else if( recommendedSongs.isNotEmpty)...[
              const Text(
                'Dành riêng cho bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230, // đủ chứa 3 bài
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (recommendedSongs.length / 3).ceil(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, columnIndex) {
                    final start = columnIndex * 3;
                    final end = (start + 3 < recommendedSongs.length)
                        ? start + 3
                        : recommendedSongs.length;
                    final columnSongs = recommendedSongs.sublist(start, end);

                    return Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 330,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(columnSongs.length, (i) {
                          final song = columnSongs[i];
                          final globalIndex = start + i;

                          return Padding(
                            padding: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    song["cover_url"] ?? "",
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.music_note,
                                            color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                title: Row(
                                  children: [
                                    if (audioProvider.currentIndex == globalIndex && audioProvider.playlistId == "DanhRiengChoBan") ...[
                                      const SizedBox(width: 2),
                                      if(audioProvider.isPlaying)...[
                                        EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                                        const SizedBox.shrink(),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            song["title"],
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
                                            song["title"],
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
                                          song["title"],
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
                                  song["artist_name"] ?? "Không rõ nghệ sĩ",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
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
                                                      child: song["cover_url"].isNotEmpty
                                                          ? Image.network(
                                                        song["cover_url"],
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
                                                    title: Text(song["title"]),
                                                    subtitle: Text(song["artist_name"]),
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
                                                      addSongToPlaylist(song["song_id"].toString());
                                                    },
                                                  ),
                                                  ListTile(
                                                      leading: const Icon(Icons.remove_circle_outline),
                                                      title: const Text('Tải xuống'),
                                                      onTap: () async {
                                                        if (isDownloading) return; // chặn spam
                                                        setState(() => isDownloading = true);

                                                        await downloadSong(song["song_id"].toString(), song["title"], song["audio_url"], song["artist_name"], song["cover_url"]);

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

                                  await audioProvider.setPlaylist(recommendedSongs, startIndex: globalIndex,);

                                  audioProvider.setCurrentSong(globalIndex);
                                  audioProvider.setPlaying(true);
                                  audioProvider.setPlaylistId("DanhRiengChoBan");

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
                              ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ]
            else...[
              const Center(
                child: Text(
                  "Không có dữ liệu gợi ý",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],

            if(topArtists.isNotEmpty && topArtists.length >= 4)...[
              const Text(
                'Những nghệ sĩ bạn hay nghe nhất',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: topArtists.length,
                  itemBuilder: (context, index) {
                    final artist = topArtists[index];
                    return GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(artist['avatar_url']),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 80,
                              child: Text(
                                artist['artist_name'],
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      ),
                      onTap: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context)=>ArtistDetailScreen(artistId: artist['artist_id'].toString()),
                              settings: const RouteSettings(name: "artist_detail"),
                            )
                        );
                      },
                    );
                  },
                ),
              ),
            ]
            else if(bestPLayCountArtists.isNotEmpty)...[
              const Text(
                'Có thể bạn cũng thích',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: bestPLayCountArtists.length,
                  itemBuilder: (context, index) {
                    final artist = bestPLayCountArtists[index];
                    return GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(artist['avatar_url']),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 80,
                              child: Text(
                                artist['artist_name'],
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      ),
                      onTap: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context)=>ArtistDetailScreen(artistId: artist['artist_id'].toString()),
                              settings: const RouteSettings(name: "artist_detail"),
                            )
                        );
                      },
                    );
                  },
                ),
              ),
            ]
            else...[
              const Center(
                child: Text(
                  "Không có dữ liệu",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],

            if(recentSongs.isNotEmpty && recentSongs.length >= 3)...[
              const Text(
                'Những bài hát hay nghe gần đây',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 230, // đủ chứa 3 bài
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (recentSongs.length / 3).ceil(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, columnIndex) {
                    final start = columnIndex * 3;
                    final end = (start + 3 < recentSongs.length)
                        ? start + 3
                        : recentSongs.length;
                    final columnSongs = recentSongs.sublist(start, end);

                    return Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 330,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(columnSongs.length, (i) {
                          final song = columnSongs[i];
                          final globalIndex = start + i;

                          return Padding(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  song["cover_url"] ?? "",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.music_note,
                                        color: Colors.white54),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  if (audioProvider.currentIndex == globalIndex && audioProvider.playlistId == "NhungBaiHatHayNgheGanDay") ...[
                                    const SizedBox(width: 2),
                                    if(audioProvider.isPlaying)...[
                                      EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                                      const SizedBox.shrink(),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          song["title"],
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
                                          song["title"],
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
                                        song["title"],
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
                                song["artist_name"] ?? "Không rõ nghệ sĩ",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
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
                                                    child: song["cover_url"].isNotEmpty
                                                        ? Image.network(
                                                      song["cover_url"],
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
                                                  title: Text(song["title"]),
                                                  subtitle: Text(song["artist_name"]),
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
                                                    addSongToPlaylist(song["song_id"].toString());
                                                  },
                                                ),
                                                ListTile(
                                                    leading: const Icon(Icons.remove_circle_outline),
                                                    title: const Text('Tải xuống'),
                                                    onTap: () async {
                                                      if (isDownloading) return; // chặn spam
                                                      setState(() => isDownloading = true);

                                                      await downloadSong(song["song_id"].toString(), song["title"], song["audio_url"], song["artist_name"], song["cover_url"]);

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

                                await audioProvider.setPlaylist(recentSongs, startIndex: globalIndex,);

                                audioProvider.setCurrentSong(globalIndex);
                                audioProvider.setPlaying(true);
                                audioProvider.setPlaylistId("NhungBaiHatHayNgheGanDay");

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
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ]
            else...[
              SizedBox.shrink(),
            ],


            // thể loại
            const Text(
              'Thể loại',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {

                  final genres = ["Nhạc Việt", "Nhạc Nhật", "Nhạc Âu", "Nhạc Hàn"];
                  final Map<int, String> gs = {
                    25: "Việt Nam",
                    15: "Nhạc Nhật",
                    1:  "Nhạc Âu",
                    14: "Nhạc Hàn",
                  };
                  final keys = gs.keys.toList();
                  final values = gs.values.toList();

                  final colors = [
                    [Color(0xFFFF6B6B), Color(0xFFEE5A6F)], // Red gradient
                    [Color(0xFFFFB347), Color(0xFFFF8C42)], // Orange gradient
                    [Color(0xFF4FC3F7), Color(0xFF29B6F6)], // Blue gradient
                    [Color(0xFFBA68C8), Color(0xFFAB47BC)], // Purple gradient
                  ];

                  return GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 170,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors[index],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors[index][0].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                              // Decorative circle
                              Positioned(
                              right: -20,
                                top: -4,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Content
                              Center(
                                child: Text(
                                  values[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          )
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context)=>GenreDetailScreen(genreId: keys[index].toString()),
                            settings: const RouteSettings(name: "genre_detail"),
                          ),
                      );
                    },
                  );
                },
              ),
            ),


            const SizedBox(height: 24),

            // Album mới
            const Text(
              'Album mới phát hành',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(
                3,
                    (index) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/album${index + 1}.jpg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const Text(
                    'Tên album',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tên nghệ sĩ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),


      bottomNavigationBar: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.bottomToTop,
              child: JustAudioDemo(),
            ),
          );
        },
        child:  MiniPlayer(),
      ),

    );
  }
}
