import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/design/EqualizerAnimation.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../function/handle_framework.dart';
import '../home_screens/just_audio_demo.dart';
import '../home_screens/mini_player.dart';
import '../premium_screen/PremiumBottomSheet.dart';
import '../provider/audio_player_provider.dart';
import '../provider/user_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  final String playlistId;
  final String userId;

  const PlaylistDetailScreen({
    super.key,
    required this.userId,
    required this.playlistName,
    required this.playlistId,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {

  String playlistName = "";
  bool playStatus = false;
  bool repeatStatus = true;

  List<Map<String, dynamic>> topSongs = [];
  List<Map<String, dynamic>> playlistOnlineSongs = [];
  bool isLoading = true;
  bool loading = true; // loading bài hát gợi ý
  int? currentIndex; // để biết bài nào đang phát
  bool isDownloading = false;

  List<Map<String, dynamic>> songs = [];

  // lấy song từ playlist từ internet
  Future<void> getPlaylistSongs(String userId, String playlistId) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/playlist/get_playlist_songs.php?playlist_id=$playlistId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        setState(() {
          playlistOnlineSongs = List<Map<String, dynamic>>.from(data["songs"]);
        });
      } else {
        throw Exception(data["message"]);
      }
    } else {
      throw Exception("Lỗi kết nối server");
    }
  }

  // load để lấy 4 hình bài đầu làm banner (từ csdl, tạm thời không dùng)
  Future<List<Map<String, dynamic>>> loadSongCover(String playlistId) async {
    String url = "http://10.0.2.2:8081/music_API/get_song_list_api/get_songs_from_playlist.php";

    var response = await http.post(
      Uri.parse(url),
      body: json.encode({"playlistId": playlistId.toString()}),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data["status"] == "success" && data["songs"] != null) {
        final songs = List<Map<String, dynamic>>.from(data["songs"]);
        return songs;

      } else {
        print("Error: ${data["message"]}");
      }
    } else {
      print("Failed to connect to server");
    }
    return [];
  }

  //List<Map<String, dynamic>> playlists = [];

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

  @override
  void initState() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.playlistName = widget.playlistName;
    super.initState();
    fetchOnlineSongs();
    fetchStarterSongs();
    getPlaylistSongs(user!.id.toString(), widget.playlistId.toString());
    playlistName = widget.playlistName.toString();
  }

  Future<dynamic> showMessage(String _msg) async{
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

  // lấy 50 hot online
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

  // thêm bài hát vào playlist internet
  Future<void> addToPlaylist(String songId, String userId, String playlistId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/add_to_playlist.php");
    final body = json.encode({
      "user_id": userId,
      "playlist_id": playlistId,
      "song_id": songId
    });

    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: body);
    await getPlaylistSongs(userId, widget.playlistId);

    print(response.body);
  }

  // xóa 1 bài hát từ playlist internet
  Future<void> removeFromPlaylist(String songId, String userId, String playlistId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/remove_song_from_playlist.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "playlist_id": playlistId,
        "song_id": songId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        showSuccessToast("Đã xóa khỏi danh sách phát");
      } else {
        showMessage(data["message"]);
      }
    } else {
      showMessage("Lỗi kết nối máy chủ");
    }
  }

  // xóa nhiều bài
  Future<void> removeListSongs(List<String> removedSongs, String userId, String playlistId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/remove_list_songs_from_playlist.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "playlist_id": playlistId,
        "song_ids": removedSongs,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        showSuccessToast("Đã xóa khỏi danh sách phát");
      } else {
        showMessage(data["message"]);
      }
    } else {
      showMessage("Lỗi kết nối máy chủ");
    }
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
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // trả về true khi nhấn nút Back vật lý
        return false; // chặn pop mặc định (vì ta đã pop thủ công)
      },
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                  onPressed: (){
                    Navigator.pop(context, true);
                  },
                  icon: Icon(Icons.arrow_back_ios_rounded, size: 20,)
              ),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
            ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // thêm dòng này
              children: [
                _buildPlaylistBanner_internet(context, widget.playlistId.toString(), widget.playlistName.toString(), playlistOnlineSongs),
                _buildSongListInPlayList(context, audioProvider),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Các bài hát được đề xuất",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRecommendSongList(context),
                const SizedBox(height: 80),

              ],
            ),
          ),

        ),
    );
  }

  Widget _buildPlaylistBanner_internet(BuildContext context, String playlistId, String playlistName, List<Map<String, dynamic>> playlistOnlineSongs,) {
    final songs = playlistOnlineSongs;
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen:false);
    // Banner hiển thị ảnh playlist
    Widget bannerContent;
    if (songs.length >= 4) {
      // Hiển thị 4 ảnh (2x2)
      bannerContent = GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Image.network(
            song["cover_url"] ?? "",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800),
          );
        },
      );
    } else if (songs.isNotEmpty) {
      bannerContent = Image.network(
        songs[0]["cover_url"] ?? "",
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800),
      );
    } else {
      bannerContent = Container(
        color: Colors.grey.shade800,
        child: const Icon(Icons.library_music, color: Colors.white54, size: 60),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (songs.isNotEmpty)
            Column(
              children: [
                // Ảnh bìa playlist
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: bannerContent,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Thông tin playlist
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audioProvider.playlistName.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${songs.length} bài hát",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: audioProvider.isShuffle
                              ? const FaIcon(FontAwesomeIcons.shuffle,
                              color: Color(0xFF154D71), size: 22)
                              : const FaIcon(FontAwesomeIcons.shuffle,
                              color: Colors.white60, size: 22),
                          onPressed: () {
                            setState(() => audioProvider.toggleShuffle());
                          },
                        ),

                        // Nút play/pause
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white60,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(8),
                          ),

                          child: Icon(
                            audioProvider.isPlaying && audioProvider.playlistId == widget.playlistId
                                ? Icons.pause_rounded : Icons.play_arrow,
                            color: const Color(0xFF0F0F1C),
                            size: 35,
                          ),

                          onPressed: () async {
                            if(audioProvider.playlistId != widget.playlistId && audioProvider.playlist.isNotEmpty){
                              List<Map<String, dynamic>> songsList = playlistOnlineSongs;
                              await audioProvider.setPlaylist(songsList, startIndex: audioProvider.currentIndex);
                              audioProvider.setPlaying(true);
                              audioProvider.setCurrentSong(audioProvider.currentIndex);
                              audioProvider.playlistId = widget.playlistId;
                            }
                            else{
                              audioProvider.playlistId = widget.playlistId;

                              if(audioProvider.playlist.isEmpty && audioProvider.isPlaying == false){
                                List<Map<String, dynamic>> songsList = playlistOnlineSongs;
                                audioProvider.setPlaying(true);
                                await audioProvider.setPlaylist(songsList, startIndex: audioProvider.currentIndex);
                                audioProvider.setCurrentSong(audioProvider.currentIndex);

                                audioProvider.player.play();
                                audioProvider.setPlaying(true);

                              }
                              else if(audioProvider.isPlaying == true){
                                audioProvider.player.pause();
                                audioProvider.setPlaying(false);

                              }
                              else if(audioProvider.isPlaying == false){
                                audioProvider.player.play();
                                audioProvider.setPlaying(true);

                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Hàng các card tính năng
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      MinePartCard(
                        title: 'Thêm',
                        color1: Colors.white10,
                        color2: Colors.white12,
                        icon: Icons.add_circle_outline,
                        iconColor: Colors.white,
                        onPressed: () => _searchSongs(context),
                      ),
                      const SizedBox(width: 12),
                      MinePartCard(
                        title: 'Chỉnh sửa',
                        color1: Colors.white10,
                        color2: Colors.white12,
                        icon: Icons.edit_note,
                        iconColor: Colors.white,
                        onPressed: () => _editPlaylist(context),
                      ),
                      const SizedBox(width: 12),
                      MinePartCard(
                        title: 'Tên và thông tin chi tiết',
                        color1: Colors.white10,
                        color2: Colors.white12,
                        icon: Icons.edit_outlined,
                        iconColor: Colors.white,
                        onPressed: () => _playlistInfomation(context),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
          // Nếu playlist trống
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ảnh bìa playlist
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: bannerContent,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlistName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${songs.length} bài hát",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white60.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextButton(
                        onPressed: () => _searchSongs(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 25, color: Colors.black),
                            SizedBox(width: 6),
                            Text(
                              "Thêm nhạc vào danh sách",
                              style: TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  // danh sách nhạc trong playlist từ internet
  Widget _buildSongListInPlayList(BuildContext context, AudioPlayerProvider audioProvider) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlistOnlineSongs.length,
      itemBuilder: (context, index) {
        final song = playlistOnlineSongs[index];
        final songId = song['song_id'].toString();
        final audioUrl = song['audio_url'];
        final coverUrl = song['cover_url'] ?? '';
        final songTitle = song['title'] ?? 'Không có tiêu đề';
        final artist = song['artist_name'] ?? 'Không rõ nghệ sĩ';
        //final playCount = song['play_count'] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

            // ảnh bìa
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

            subtitle: Text(
              artist,
              style: const TextStyle(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // tiêu đề
            title: Row(
              children: [
                if (audioProvider.currentIndex == index && audioProvider.playlistId == widget.playlistId) ...[
                  const SizedBox(width: 2),
                  if(audioProvider.isPlaying)...[
                    EqualizerAnimation(isPlaying: audioProvider.isPlaying),
                    const SizedBox.shrink(),
                    const SizedBox(width: 6),
                  ]
                  else ...[
                    const SizedBox.shrink(),
                  ]
                ],
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
            ),

            // nút more
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
                                  await getUserPlaylists();
                                  setState(() {});
                                  selectedPlaylists = [];
                                  addSongToPlaylist(songId);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.remove_circle_outline),
                                title: const Text('Xóa khỏi danh sách phát'),
                                onTap: () async {
                                  await removeFromPlaylist(songId, user!.id.toString(), widget.playlistId);
                                  await getPlaylistSongs(user!.id.toString(), widget.playlistId); // Cập nhật lại danh sách
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                              ),
                               ListTile(
                                leading: Icon(Icons.download),
                                title: Text('Tải xuống'),
                                 onTap: () async {
                                   if (isDownloading) return; // chặn spam
                                   setState(() => isDownloading = true);

                                   await downloadSong(songId, songTitle, audioUrl, artist, coverUrl);

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

            // phát nhạc
            onTap: () async {

              final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
              List<Map<String, dynamic>> songsList = playlistOnlineSongs;
              await audioProvider.setPlaylist(songsList, startIndex: index, statusIndex: 1);
              audioProvider.setCurrentSong(index);
              audioProvider.setPlaying(true);
              audioProvider.playlistId = widget.playlistId;

              // khi nhạc phát mới hiện thị, mới đăng nhập vào hoặc mới đăng xuất ra thì k hiển thị
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
            isLoading = false;
          });

          print("🎵 Tải thành công ${songs.length} bài hát");
          return onlineSongs;
        } else {
          print("⚠️ API trả về không có danh sách bài hát");
        }
      } else {
        print("❌ Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Lỗi khi tải danh sách bài hát: $e");
    }

    return [];
  }

  // tìm bài hát để thêm vào playlist (finished)
  void _searchSongs(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    TextEditingController searchController = TextEditingController();

    // Danh sách hiển thị (copy từ danh sách gốc)
    List<Map<String, dynamic>> filteredSongs = List.from(onlineSongs);
    print(filteredSongs);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            // Hàm loại bỏ dấu tiếng Việt
            String removeVietnameseTones(String str) {
              str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
              str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
              str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
              str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
              str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
              str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
              str = str.replaceAll(RegExp(r'[đ]'), 'd');
              str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
              str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
              str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
              str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
              str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
              str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
              str = str.replaceAll(RegExp(r'[Đ]'), 'D');
              return str;
            }

            // Hàm lọc bài hát (không phân biệt hoa/thường và dấu)
            void filterSongs(String query) {
              final normalizedQuery = removeVietnameseTones(query.toLowerCase().trim());
              final lowerQuery = query.toLowerCase().trim();

              setModalState(() {
                filteredSongs = onlineSongs.where((song) {
                  final rawTitle = (song["title"] ?? "").toString();
                  final rawArtist = (song["artist"] ?? "").toString();

                  final title = rawTitle.toLowerCase();
                  final artist = rawArtist.toLowerCase();

                  final titleNoTone = removeVietnameseTones(title);
                  final artistNoTone = removeVietnameseTones(artist);

                  return title.contains(lowerQuery) ||
                      artist.contains(lowerQuery) ||
                      titleNoTone.contains(normalizedQuery) ||
                      artistNoTone.contains(normalizedQuery);
                }).toList();
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF37353E), Color(0xFF44444E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh tiêu đề
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Thêm nhạc vào danh sách",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 24, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Ô tìm kiếm
                      TextField(
                        controller: searchController,
                        onChanged: filterSongs,
                        decoration: InputDecoration(
                          hintText: "Tìm bài hát hoặc nghệ sĩ",
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF44444E),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        searchController.text.isEmpty
                            ? "Bài hát đề xuất"
                            : "Kết quả tìm kiếm (${filteredSongs.length})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredSongs.isEmpty
                            ? const Center(
                          child: Text(
                            "Không tìm thấy bài hát nào.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = filteredSongs[index];
                            final songId = song["song_id"] ?? "";
                            final title = song["title"] ?? "Unknown Title";
                            final artist = song["artist"] ?? "Unknown Artist";
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
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.music_note, color: Colors.grey, size: 40),
                                ),
                              )
                                  : const Icon(Icons.music_note, color: Colors.grey, size: 40),
                              title: Text(
                                title,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                artist,
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                                onPressed: () async {
                                  await addToPlaylist(songId.toString(), user!.id.toString(), widget.playlistId.toString());
                                  showSuccessToast("Đã thêm vào danh sách phát");
                                  print(widget.playlistId!.toString());
                                  await getPlaylistSongs(user.id, widget.playlistId);
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 50),
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

  // danh sách nhạc gợi ý lấy từ internet (finished)
  Widget _buildRecommendSongList(BuildContext context){
    final user = Provider.of<UserProvider>(context, listen: false).user;
    return starterSongs.isEmpty
        ? const Center(child: Text("Không có dữ liệu"))
        : ListView.builder(
      shrinkWrap: true, // Cho phép co theo nội dung
      physics: const NeverScrollableScrollPhysics(), // Không cuộn riêng
      itemCount: starterSongs.length,
      itemBuilder: (context, index) {
        final song = starterSongs[index];
        final song_id = song["song_id"] ?? "";
        final title = song["title"] ?? "Unknown Title";
        final artist = song["artist_name"] ?? "Unknown Artist";
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
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.music_note,
                  color: Colors.grey, size: 40),
            ),
          )
              : const Icon(Icons.music_note,
              color: Colors.grey, size: 40),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            artist,
            style: const TextStyle(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(Icons.add_circle_outline),
            color: Colors.white70,
            onPressed: () async {
              await addToPlaylist(song_id.toString(), user!.id.toString(), widget.playlistId.toString());
              showSuccessToast("Đã thêm vào danh sách phát");
              await getPlaylistSongs(user.id, widget.playlistId);
              setState(() {});
            },
          ),
          onTap: () async {
            final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

            List<Map<String, dynamic>> songsList = starterSongs;

            await audioProvider.setPlaylist(songsList, startIndex: index);

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

  // chỉnh sửa playlist
  void _editPlaylist(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    // các bài nhạc trong playlist
    List<Map<String, dynamic>> songs = List.from(playlistOnlineSongs);

    List<String> removeIndex = [];
    bool saveStatus = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1E201E),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh tiêu đề
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:  Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              child: Text("Hủy", style: TextStyle(fontSize: 17, color: Colors.white)),
                              onPressed: removeIndex.isNotEmpty
                                  ? () async {
                                final shouldExit = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        "Hủy thay đổi",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        "Bạn có chắc muốn hủy chỉnh sửa? Các thay đổi chưa lưu sẽ bị mất.",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      actionsAlignment: MainAxisAlignment.end,
                                      actions: [
                                        TextButton(
                                          child: const Text(
                                            "Hủy",
                                            style: TextStyle(color: Colors.black, fontSize: 18),
                                          ),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF37353E),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: const Text("Tiếp tục chỉnh sửa", style: TextStyle(color: Colors.white, fontSize: 18)),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldExit == true) {
                                  Navigator.pop(context); // đóng BottomSheet
                                }
                              }
                                  : () => Navigator.pop(context),

                            ),
                            const Text(
                              "Chỉnh sửa playlist",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            saveStatus == false ?
                              TextButton(
                                child: Text("Lưu", style: TextStyle(fontSize: 17, color: Color(0xFF393E46))),
                                onPressed: () {}
                              ) :
                              TextButton(
                                  child: Text("Lưu", style: TextStyle(fontSize: 17, color: Color(0xFF059212))),
                                  onPressed: () async {
                                    await removeListSongs(removeIndex, user!.id.toString(), widget.playlistId.toString());
                                    await getPlaylistSongs(user!.id.toString(), widget.playlistId.toString());
                                    setState(() {});
                                    Navigator.pop(context);
                                  }
                              )
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : songs.isEmpty
                            ? const Center(
                          child: Text(
                            "Không tìm thấy bài hát nào.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            final song_id = song["song_id"] ?? "";
                            final title = song["title"] ?? "Unknown Title";
                            final artist = song["artist_name"] ?? "Unknown Artist";
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
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.music_note, color: Colors.grey, size: 40),
                                ),
                              )
                                  : const Icon(Icons.music_note, color: Colors.grey, size: 40),
                              title: Text(
                                title,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                artist,
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                                onPressed: () async {
                                  setModalState(() {
                                    removeIndex.add(song_id.toString());
                                    songs.removeAt(index);
                                    saveStatus = true;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 50),
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

  Future<void> updatePlaylistName(String userId, String playlistId, String newName) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/update_playlist_name.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "playlist_id": playlistId,
          "new_name": newName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          print("Playlist updated successfully!");
        } else {
          print("${data["message"]}");
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating playlist name: $e");
    }
  }

  Widget _editPlaylistInformation(BuildContext context, String playlistId, String playlistName, List<Map<String, dynamic>> playlistOnlineSongs,) {
    final songs = playlistOnlineSongs;
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController(text: playlistName);

    Widget bannerContent;
    if (songs.length >= 4) {
      bannerContent = GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Image.network(
            song["cover_url"] ?? "",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800),
          );
        },
      );
    } else if (songs.isNotEmpty) {
      bannerContent = Image.network(
        songs[0]["cover_url"] ?? "",
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800),
      );
    } else {
      bannerContent = Container(
        color: Colors.grey.shade800,
        child: const Icon(Icons.library_music, color: Colors.white54, size: 60),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              // Ảnh bìa playlist
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: bannerContent,
                ),
              ),
              const SizedBox(width: 16),

              // TextField sửa tên playlist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tên playlist",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black38,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isNotEmpty && newName != playlistName) {
                          await updatePlaylistName(user!.id.toString() ,playlistId, newName); // 👈 bạn định nghĩa API này
                          showSuccessToast("Đã cập nhật tên playlist");
                          setState(() {
                            audioProvider.playlistName = newName;
                          });
                          Navigator.pop(context);
                        }else{
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // tên và thông tin bài hát
  void _playlistInfomation(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    // các bài nhạc trong playlist
    List<Map<String, dynamic>> songs = List.from(playlistOnlineSongs);

    List<String> removeIndex = [];
    bool saveStatus = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1E201E),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh tiêu đề
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Nút Hủy bên trái
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Hủy",
                                style: TextStyle(fontSize: 17, color: Colors.white),
                              ),
                            ),

                            // Tiêu đề ở giữa
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "Tên và thông tin bài hát",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // Chỗ trống bên phải để cân đối với nút “Hủy”
                            const SizedBox(width: 60),
                          ],
                        ),
                      ),


                      const SizedBox(height: 20),
                      _editPlaylistInformation(context, widget.playlistId, widget.playlistName, songs),

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

}
class MinePartCard extends StatelessWidget {
  final String title;
  final Color color1;
  final Color color2;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;

  const MinePartCard({
    super.key,
    required this.title,
    required this.color1,
    required this.color2,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 25),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
    );
  }
}

