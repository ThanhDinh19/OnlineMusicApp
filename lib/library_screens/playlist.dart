import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/library_screens/playlist_detail_screen.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import '../test.dart';

class Playlist extends StatefulWidget {
  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  List<Map<String, dynamic>> onlinePlaylists = [];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) getUserPlaylists();
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
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: onlinePlaylists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                createNewPlaylist(context, (namePlaylist) async {
                  await getUserPlaylists();
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [Colors.white10, Colors.white12],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_circle_outline, color: Colors.grey, size: 27),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Tạo danh sách phát",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          );
        }

        final playlist = onlinePlaylists[index - 1];
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
            playlist["name"] ?? "Chưa đặt tên",
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "$songCount bài hát",
            style: const TextStyle(color: Colors.grey),
          ),
          onTap: () async {
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailScreen(
                  playlistName: playlist["name"],
                  playlistId: playlist["playlist_id"].toString(),
                  userId: user!.id.toString(),
                ),
              ),
            );

            if (shouldRefresh == true) {
              await getUserPlaylists();
            }
          },
        );
      },
    );
  }
}
