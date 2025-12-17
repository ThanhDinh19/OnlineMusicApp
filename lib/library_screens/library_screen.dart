import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/library_screens/playlist.dart';
import 'package:music_app/provider/audio_player_provider.dart';
import 'package:music_app/provider/favorite_song_provider.dart';
import 'package:music_app/provider/load_song_provider.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../design/EqualizerAnimation.dart';
import '../function/handle_framework.dart';
import '../home_screens/just_audio_demo.dart';
import '../home_screens/mini_player.dart';
import '../premium_screen/PremiumBottomSheet.dart';
import '../provider/favorite_album_provider.dart';
import '../search_screen/album_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final user = Provider.of<UserProvider>(context, listen: false).user;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = user!.id.toString();

      Provider.of<FavoriteAlbumProvider>(context, listen: false)
          .loadAlbumFavorites(uid);

      Provider.of<FavoriteSongProvider>(context, listen: false)
          .loadSongFavorites(uid);

      Provider.of<LoadSongProvider>(context, listen: false)
          .loadDownloadedSongs(uid);
    });
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user!.id.toString();
    Provider.of<FavoriteAlbumProvider>(context, listen: false)
        .loadAlbumFavorites(uid);
    Provider.of<LoadSongProvider>(context, listen: false)
        .loadDownloadedSongs(uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50), // tổng chiều cao của AppBar + TabBar
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 40,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.indigoAccent,
            labelColor: Colors.indigoAccent,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "Đã tải"),
              Tab(text: "Playlist"),
              Tab(text: "Album"),
              Tab(text: "Yêu thích"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DownloadedTab(userId: user!.id.toString()),
          Playlist(),
          _buildListAlbumTab(),
          _buildFavoriteTab(),
        ],
      ),


    );
  }

  // Tab 3: Album
  Widget _buildListAlbumTab() {
    final favoriteProvider = Provider.of<FavoriteAlbumProvider>(context);
    final albums = favoriteProvider.albums;

    if (albums.isEmpty) {
      return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.album_outlined, size: 50,),
              SizedBox(height: 20),
              Text(
                "Bạn chưa có album nào",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Hãy tìm kiếm album bạn yêu thích để thêm vào",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final item = albums[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item['cover_url'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            title: Text(
              item['name'] ?? "Chưa có tên",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              item['description'] ?? "Không có mô tả",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(
                    albumId: item['album_id'].toString(),
                    albumName: item['name'],
                    albumCover: item['cover_url'],
                  ),
                  settings: const RouteSettings(name: "albumScreen"),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Tab 4: Yêu thích
  Widget _buildFavoriteTab() {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final favoriteProvider = Provider.of<FavoriteSongProvider>(context);
    final favoriteSongs = favoriteProvider.songs;
    return favoriteSongs.isEmpty ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 50,),
            SizedBox(height: 20),
            Text(
              "Chưa có bài hát yêu thích",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "Hãy tìm kiếm bài hát bạn yêu thích để thêm vào",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
    ) :
    ListView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = favoriteSongs[index];
        final songId = song["song_id"].toString() ?? "";
        final title = song["title"] ?? "Unknown Title";
        final artist = song["artist_name"] ?? "Unknown Artist";
        final audioUrl = song["audio_url"] ?? "";
        final duration = song["duration"] ?? "";
        final coverUrl = song["cover_url"] ?? "";
        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                coverUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Row(
              children: [
                if (audioProvider.currentIndex == index && audioProvider.playlistId == "FavoriteSong") ...[
                  const SizedBox(width: 2),
                  if(audioProvider.isPlaying)...[
                    EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                    const SizedBox.shrink(),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
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
                        title,
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
                      title,
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
            subtitle: Text(artist,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
                                title: Text(title),
                                subtitle: Text(artist),
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

                                    await downloadSong(songId, title, audioUrl, artist, coverUrl);

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
                  context, listen: false);

              // Gọi API để lấy toàn bộ danh sách
              List<Map<String, dynamic>> songsList = favoriteSongs;

              // Set playlist & bài hiện tại
              await audioProvider.setPlaylist(songsList, startIndex: index,);
              audioProvider.setCurrentSong(index);
              audioProvider.setPlaying(true);
              audioProvider.setPlaylistId("FavoriteSong");

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
      },
    );
  }

}

class DownloadedTab extends StatefulWidget {
  final String userId;
  const DownloadedTab({required this.userId});

  @override
  State<DownloadedTab> createState() => _DownloadedTabState();
}

class _DownloadedTabState extends State<DownloadedTab> {
  final AudioPlayer player = AudioPlayer();

  bool isLoading = true;
  int? currentIndex; // để biết bài nào đang phát
  @override
  void initState() {
    super.initState();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,       // vị trí giữa màn hình
      backgroundColor: Colors.black45.withOpacity(0.6),      // màu nền
      textColor: Colors.white,            // màu chữ
      fontSize: 16.0,                     // cỡ chữ
    );

    Future.delayed(Duration(seconds: 1), () {
      Fluttertoast.cancel(); // ẩn thủ công sau 1 giây
    });
  }

  Future<void> deleteDownloadedSong(BuildContext context, String userId, String songId, String localPath, { required VoidCallback onSuccess}) async {
    try {
      final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/download/delete_downloaded_song.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "song_id": songId,
        }),
      );

      final data = jsonDecode(response.body);
      print("body: ${data}");
      if (data["status"] == "success") {

        try {
          final file = File(localPath);
          if (await file.exists()) {
            await file.delete();
            print("Đã xoá file local: $localPath");
          } else {
            print("Không tìm thấy file local: $localPath");
          }
        } catch (e) {
          print("Lỗi xoá file local: $e");
        }

        showToast("Đã xoá bài tải xuống");
        onSuccess();

      } else {
        showToast(data["message"]);
      }
    } catch (e) {
      showToast("Lỗi kết nối server");
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    final downloadedSongProvider = Provider.of<LoadSongProvider>(context, listen: false);
    final downloadedSongs = downloadedSongProvider.downloadedSongs;
    return downloadedSongs.isEmpty
        ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_circle_down, size: 50,),
            SizedBox(height: 20),
            Text(
              "Chưa có bài hát tải xuống",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
    )
        : ListView.builder(
      shrinkWrap: true, // Giới hạn chiều cao theo nội dung
      physics: const NeverScrollableScrollPhysics(), // Tắt cuộn bên trong
      itemCount: downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = downloadedSongs[index];
        final songId = song["song_id"].toString() ?? "";
        final title = song["title"] ?? "Unknown Title";
        final artist = song["artist"] ?? "Unknown Artist";
        final audioLocalFile = song["local_path"] ?? "";
        final coverUrl = song["cover_url"] ?? "";

        return ListTile(
          leading: coverUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              coverUrl,
              width: 60,
              height: 60,
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
          title: Row(
            children: [
              if (audioProvider.currentIndex == index && audioProvider.playlistId == "DownloadedSong") ...[
                const SizedBox(width: 2),
                if(audioProvider.isPlaying)...[
                  EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                  const SizedBox.shrink(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
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
                      title,
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
                    title,
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
                              title: Text(title),
                              subtitle: Text(artist),
                            ),

                            const Divider(color: Colors.white24),

                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text('Chia sẻ'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.remove_circle_outline),
                              title: const Text('Xóa bài đã tải'),
                              onTap: ()  {
                                deleteDownloadedSong(
                                  context,
                                 userId.toString(),
                                 songId.toString(),
                                  audioLocalFile,
                                  onSuccess: () {
                                    setState(() {
                                      downloadedSongs.removeWhere((e) => e["song_id"] == song["song_id"]);
                                    });
                                  },
                                );
                                Navigator.pop(context);
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

            final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

            // Gọi API để lấy toàn bộ danh sách
            List<Map<String, dynamic>> songsList = downloadedSongs;

            // Set playlist & bài hiện tại
            await audioProvider.setOfflinePlaylist(songsList, startIndex: index,);

            audioProvider.setCurrentSong(index);
            audioProvider.setPlaying(true);
            audioProvider.setPlaylistId("DownloadedSong");

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
}



