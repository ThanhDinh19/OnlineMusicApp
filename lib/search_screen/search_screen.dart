import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/search_screen/album_detail_screen.dart';

import '../artist/artist_detail_screen.dart';
import '../design/EqualizerAnimation.dart';
import '../function/handle_framework.dart';
import '../home_screens/just_audio_demo.dart';
import '../home_screens/mini_player.dart';
import '../premium_screen/PremiumBottomSheet.dart';
import '../provider/audio_player_provider.dart';
import '../provider/user_provider.dart'; // nếu có

class SearchScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SearchScreen({super.key, this.onBack});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List albums = [];
  List songs = [];
  List artists = [];
  bool isLoading = false;
  bool isDownloading = false;
  // recent searches
  List<String> recentSearches = [];
  final String recentKey = "recent_searches_v1";
  bool isSearching = false; // false -> show recent, true -> show results

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // initially show recent (do not call API)
    _searchController.addListener(_onSearchTextChanged);
    fetchOnlineSongs();
  }

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
            isLoading = false;
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final text = _searchController.text;
    // nếu có text -> đặt isSearching true (bắt đầu hiển thị kết quả khi gọi)
    // nhưng mình sẽ debounce gọi API để tránh spam requests
    if (text.trim().isEmpty) {
      setState(() => isSearching = false);
      // clear previous results optionally:
      // setState(() { albums = []; songs = []; artists = []; });
      _debounce?.cancel();
    } else {
      setState(() => isSearching = true);
      // debounce
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 450), () {
        searchAll(text.trim());
      });
    }
  }

  // ----- Recent searches persist -----
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(recentKey) ?? [];
    setState(() => recentSearches = list);
  }

  Future<void> _addRecentSearch(String q) async {
    if (q.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    // remove duplicates, add to front
    recentSearches.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    recentSearches.insert(0, q);
    // keep max 12
    if (recentSearches.length > 12) recentSearches = recentSearches.sublist(0, 12);
    await prefs.setStringList(recentKey, recentSearches);
    setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(recentKey);
    setState(() => recentSearches = []);
  }

  // ----- Search API -----
  Future<void> searchAll(String keyword) async {
    setState(() => isLoading = true);

    final q = keyword.trim();
    final url =
        "http://10.0.2.2:8081/music_API/online_music/search/get_search.php?q=${Uri.encodeComponent(q)}";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Kiểm tra đúng định dạng JSON
        if (data is Map &&
            data["albums"] is List &&
            data["songs"] is List &&
            data["artists"] is List) {
          setState(() {
            albums = List.from(data["albums"]);
            songs = List.from(data["songs"]);
            artists = List.from(data["artists"]);
          });
          // lưu recent
          await _addRecentSearch(q);
        } else {
          debugPrint("Dữ liệu không hợp lệ: $data");
          setState(() {
            albums = [];
            songs = [];
            artists = [];
          });
        }
      } else {
        debugPrint("Lỗi HTTP ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi khi tìm kiếm: $e");
    }

    setState(() => isLoading = false);
  }

  // khi user nhấn nút tìm kiếm explicit
  void _onSearchSubmitted(String text) {
    final q = text.trim();
    if (q.isEmpty) return;
    // đảm bảo isSearching true
    setState(() => isSearching = true);
    searchAll(q);
  }

  // khi user tap 1 recent search
  void _onTapRecent(String q) {
    _searchController.text = q;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: q.length));
    setState(() => isSearching = true);
    searchAll(q);
  }

  // load playlist từ csdl
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

  // tạo list trạng thái chọn
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
                                  showSuccessToast("Đã thêm bài hát vào playlist");
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
                          await createNewPlaylist(context, (name) async {

                            // Gọi loadPlaylists để lấy lại danh sách
                            await getUserPlaylists();

                            // Cập nhật lại state của bottom sheet
                            setState(() {});
                          });
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

  void showSuccessToast(String message) {
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

  // lưu song vào playlists
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

  // lưu new playlist vào csdl
  Future handle_new_playlist(BuildContext context, String namePlaylistController) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    //Login API URL
    //use your local IP address instead of localhost or use Web API
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/create_playlist.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId.toString(),
        "name": namePlaylistController,
      }),
    );
    if (response.statusCode == 200) {
      //Server response into variable
      print(response.body);
      final data = jsonDecode(response.body);

      //Check Saving Status
      if (data["status"] == "success") {
        print("Save playlist into database successfully");

      } else {
        setState(() {
          //Show Error Message Dialog
          showToast("Lỗi khi tạo playlist");
        });
      }
    } else {
      setState(() {
        //Show Error Message Dialog
        showToast("Lỗi kết nối mạng");
      });
    }
  }

  // mở bottom sheet lên, sau đó nhập liệu và gọi handle_new_playlist để lưu playlist vào csdl, sau khi lưu xong thì load lại playlist
  Future createNewPlaylist(BuildContext context, Function(String) onCreate) async {
    final TextEditingController namePlaylistController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Color(0xFF1E201E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView( // SingleChildScrollView tránh overflow khi bàn phím bật.
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      "Đặt tên cho playlist của bạn",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: namePlaylistController,
                      style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: ".......",
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[850],
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Hủy",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black38,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 14),
                          ),
                          onPressed: () {
                            final name = namePlaylistController.text.trim();
                            if (name.isNotEmpty) {
                              onCreate(name);
                              handle_new_playlist(context, name).then((_) {
                                getUserPlaylists();
                              });
                              showToast("Đã tạo playlist");
                              Navigator.pop(context);
                            }
                            else{
                              showToast("Hãy đặt tên cho playlist");
                            }
                          },
                          child: Text(
                            "Tạo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // tải xuống
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
    final hasResults = albums.isNotEmpty || songs.isNotEmpty || artists.isNotEmpty;
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            //  Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () {
                      if (widget.onBack != null) widget.onBack!();
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmitted,
                      decoration: InputDecoration(
                        hintText: "Tìm bài, nghệ sĩ hoặc album...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (s) {
                        // listener đã handle debounce
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _onSearchSubmitted(_searchController.text),
                  ),
                ],
              ),
            ),

            // Nếu đang không tìm (isSearching == false) -> show recent searches
            if (!isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tìm kiếm gần đây", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        if (recentSearches.isNotEmpty)
                          TextButton(
                            onPressed: _clearRecentSearches,
                            child: const Text("Xóa", style: TextStyle(color: Colors.white54)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (recentSearches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Chưa có lịch sử tìm kiếm. Bắt đầu tìm để lưu từ khóa.", style: TextStyle(color: Colors.white54)),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: recentSearches.map((q) {
                      return ActionChip(
                        label: Text(q, style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.white10,
                        onPressed: () => _onTapRecent(q),

                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              // Bạn có thể thêm "gợi ý" khác ở đây (hot artists, top songs...)
              const SizedBox(height: 8),
              // Ví dụ: show top artists horizontally if you want (omitted)
            ],

            // Nếu isSearching == true -> show results (với spinner khi đang loading)
            if (isSearching) Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : (!hasResults)
                  ? Center(child: Text("Không tìm thấy kết quả", style: const TextStyle(color: Colors.white70)))
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  // --- ARTISTS ---
                  if (artists.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Nghệ sĩ",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: artists.length,
                        itemBuilder: (context, index) {
                          final a = artists[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArtistDetailScreen(artistId: a["artist_id"].toString()),
                                  settings: const RouteSettings(name: "artist_detail"),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundImage: NetworkImage(a["avatar_url"] ?? ""),
                                    backgroundColor: Colors.grey[800],
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      a["name"] ?? "",
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // --- ALBUMS ---
                  if (albums.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Albums",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...albums.map((album) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumDetailScreen(
                              albumId: album["album_id"].toString(),
                              albumName: album["name"],
                              albumCover: album["cover_url"] ?? "http://10.0.2.2:8081/music_API/online_music/album/album_cover/default.png",
                            ),
                            settings: const RouteSettings(name: "albumScreen"),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            album["cover_url"] ?? "http://10.0.2.2:8081/music_API/online_music/album/album_cover/default.png",
                            width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width:50,height:50,color:Colors.grey),
                          ),
                        ),
                        title: Text(album["name"] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(album["artist"] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                      ),
                    )),
                  ],

                  // --- SONGS ---
                  if (songs.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Bài hát", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    // dùng asMap để có index
                    ...songs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final song = entry.value;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            song["cover_url"] ?? "http://10.0.2.2:8081/music_API/online_music/cover/default.png",
                            width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width:50,height:50,color:Colors.grey),
                          ),
                        ),
                        title: Row(
                          children: [
                            if (audioProvider.currentIndex == index && audioProvider.playlistId == "SearchSong") ...[
                              const SizedBox(width: 2),
                              if(audioProvider.isPlaying)...[
                                EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                                const SizedBox.shrink(),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    song['title'],
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
                                    song['title'],
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
                                  song['title'],
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
                        subtitle: Text(song["artist"] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 13)),
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
                                            subtitle: Text(song["artist"]),
                                          ),

                                          const Divider(color: Colors.white24),

                                          ListTile(
                                            leading: const Icon(Icons.add_circle_outline),
                                            title: const Text('Thêm vào danh sách phát'),
                                            onTap: () async {
                                              await getUserPlaylists();
                                              setState(() {});
                                              selectedPlaylists = [];
                                              addSongToPlaylist(song["song_id"].toString());
                                            },
                                          ),
                                          ListTile(
                                              leading: Icon(Icons.download),
                                              title: Text('Tải xuống'),
                                              onTap: () async {
                                                if (isDownloading) return; // chặn spam
                                                setState(() => isDownloading = true);

                                                await downloadSong(song["song_id"].toString(), song["title"], song["audio_url"], song["artist"], song["cover_url"]);

                                                setState(() => isDownloading = false);
                                              }
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
                          List<Map<String, dynamic>> songsList = List<Map<String, dynamic>>.from(songs);

                          // Set playlist & bài hiện tại
                          await audioProvider.setPlaylist(songsList, startIndex: index,);

                          audioProvider.setCurrentSong(index);
                          audioProvider.setPlaying(true);
                          audioProvider.setPlaylistId("SearchSong");

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
                    }).toList(),

                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
