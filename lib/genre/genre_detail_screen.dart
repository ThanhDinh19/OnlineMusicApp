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
import '../home_screens/just_audio_demo.dart';
import 'package:page_transition/page_transition.dart';
import '../provider/user_provider.dart';

class GenreDetailScreen extends StatefulWidget {
  final String genreId;

  const GenreDetailScreen({
    required this.genreId,
    super.key,
  });

  @override
  GenreDetailScreenState createState() => GenreDetailScreenState();
}

class GenreDetailScreenState extends State<GenreDetailScreen> {
  bool hasChangedFavorite = false;
  bool isFavorite = false;
  int? currentIndex;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    fetchSongsByGenre(widget.genreId.toString());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  List<Map<String, dynamic>> songsByGenre = [];

  Future<void> fetchSongsByGenre(String genreId) async {
    final url = Uri.parse(
      "http://10.0.2.2:8081/music_API/online_music/song/get_songs_by_genre.php",
    );

    final response = await http.post(url, body: {
      "genre_id": genreId,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        setState(() {
          songsByGenre = List<Map<String, dynamic>>.from(data["songs"]);
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(widget.genreId),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: AnimatedOpacity(
                    opacity: _scrollOffset > 100 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _getGenreName(widget.genreId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  background: _buildBanner(widget.genreId),
                ),
              ),

              // Songs list
              songsByGenre.isEmpty
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                    strokeWidth: 3,
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.only(bottom: 120, left: 8, right: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final song = songsByGenre[index];
                      return _buildSongTile(context, song, index, audioProvider);
                    },
                    childCount: songsByGenre.length,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Map<String, dynamic> song, int index, AudioPlayerProvider audioProvider) {
    final user = Provider.of<UserProvider>(context).user;
    final songId = song["song_id"].toString() ?? "";
    final songTitle = song["title"] ?? "";
    //final playCount = song["play_count"] ?? "";
    final coverUrl = song["cover_url"] ?? "";
    final audioUrl = song["audio_url"] ?? "";
    final artistName = song["artist_name"] ?? "Unknown Artist";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.white.withOpacity(0.1),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            if (audioProvider.currentIndex == index && audioProvider.playlistId == "Genre${widget.genreId.toString()}") ...[
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
          artistName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {

            if(user == null){
              showToast("Hãy đăng nhập tài khoản để trải nghiệm\n âm nhạc tuyệt vời hơn");
              return;
            }

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
                            subtitle: Text(artistName),
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
                              addSongToPlaylist(songId.toString());
                            },
                          ),
                          ListTile(
                              leading: const Icon(Icons.remove_circle_outline),
                              title: const Text('Tải xuống'),
                              onTap: () async {
                                if (isDownloading) return; // chặn spam
                                setState(() => isDownloading = true);

                                await downloadSong(songId, songTitle, audioUrl, artistName, coverUrl);

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
          await audioProvider.setPlaylist(songsByGenre, startIndex: index);

          audioProvider.setCurrentSong(index);
          audioProvider.setPlaying(true);
          audioProvider.setPlaylistId("Genre${widget.genreId.toString()}");

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.bottomToTop,
                  child: const JustAudioDemo(),
                ),
              );
            },
            child: MiniPlayer(),
          );
        },
      ),
    );
  }

  Widget _buildBanner(String id) {
    final String title = _getGenreName(id);
    final List<Color> gradient = _getGradientColors(id).take(2).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
            top: 40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: 10,
            top: 50,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

          ),


          // Genre icon
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getGenreIcon(id),
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGenreName(String id) {
    final Map<int, String> genres = {
      25: "Việt Nam",
      15: "Nhạc Nhật",
      1: "Nhạc Âu",
      14: "Nhạc Hàn",
    };
    return genres[int.tryParse(id) ?? 25] ?? "Không rõ";
  }

  List<Color> _getGradientColors(String id) {
    final Map<int, List<Color>> colors = {
      25: [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F), const Color(0xFF121212)],
      15: [const Color(0xFFFFB347), const Color(0xFFFF8C42), const Color(0xFF121212)],
      1: [const Color(0xFF4FC3F7), const Color(0xFF29B6F6), const Color(0xFF121212)],
      14: [const Color(0xFFBA68C8), const Color(0xFFAB47BC), const Color(0xFF121212)],
    };
    return colors[int.tryParse(id) ?? 25] ?? [Colors.grey, Colors.black45, const Color(0xFF121212)];
  }

  IconData _getGenreIcon(String id) {
    final Map<int, IconData> icons = {
      25: Icons.flag,
      15: Icons.auto_awesome,
      1: Icons.language,
      14: Icons.stars,
    };
    return icons[int.tryParse(id) ?? 25] ?? Icons.music_note;
  }
}