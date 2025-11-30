import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../library_screens/playlist_detail_screen.dart';
import '../provider/load_song_provider.dart';
import '../provider/user_provider.dart';

class MyPlaylistScreen extends StatefulWidget{
  @override
  State<MyPlaylistScreen> createState() => _MyPlaylistScreenState();
}

class _MyPlaylistScreenState extends State<MyPlaylistScreen>{

  @override
  void initState() {
    super.initState();

    getUserPlaylists();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black45.withOpacity(0.6),
      textColor: Colors.white,
      fontSize: 16.0,
    );
    Future.delayed(const Duration(seconds: 1), () => Fluttertoast.cancel());
  }

  void showRenameBottomSheet(String userId, String playlistId, String oldName) {
    final TextEditingController controller =
    TextEditingController(text: oldName);

    final playlistProvider = Provider.of<LoadSongProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,       // kéo theo bàn phím
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // nút kéo
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    Text(
                      "Đổi tên playlist",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 25),

                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[850],
                        hintText: "Tên playlist mới...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),

                    SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Hủy",
                              style:
                              TextStyle(color: Colors.white70, fontSize: 16)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final newName = controller.text.trim();
                            if (newName.isEmpty) return;

                            final ok = await playlistProvider
                                .updatePlaylistName(userId, playlistId, newName);

                            if (!mounted) return;

                            if (ok) showToast("Đổi tên thành công");

                            if (mounted) Navigator.pop(context);
                          },
                          child: Text("Lưu",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void handleDeletePlaylist(String playlistId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user!.id.toString();
    final playlistProvider = Provider.of<LoadSongProvider>(context, listen: false);

    bool ok = await playlistProvider.deletePlaylist(userId, playlistId);

    if (ok) {
      showToast("Đã xóa playlist");
      setState(() {}); // Load lại danh sách
    } else {
      showToast("Xóa playlist thất bại");
    }
  }

  List<Map<String, dynamic>> playlists = [];
  Future<void> getUserPlaylists() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    final userId = userProvider!.id.toString();
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/get_user_playlists.php?user_id=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        setState(() {
          playlists = List<Map<String, dynamic>>.from(data["playlists"]);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<LoadSongProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false).user;
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: playlists.length,
        itemBuilder: (context, index) {

          // Playlist item
          final playlist = playlists[index];
          final songs = playlist["songs"] ?? [];
          final songCount = playlist["song_count"];

          Widget coverWidget;

          if (songs.length >= 4) {
            coverWidget = ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: 60,
                height: 60,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, i) => Image.network(
                    songs[i]["cover"] ?? "",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          } else if (songs.isNotEmpty) {
            coverWidget = ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                songs[0]["cover"] ?? "",
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            );
          } else {
            coverWidget = Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(5),
              ),
              child:
              const Icon(Icons.library_music, color: Colors.white54),
            );
          }

          return ListTile(
            leading: coverWidget,
            title: Text(
              playlist["name"] ?? "Chưa đặt tên",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "$songCount bài hát",
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: PopupMenuButton(
              color: Colors.grey[900],
              icon: Icon(Icons.more_horiz, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "rename",
                  child: Text("Đổi tên", style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Text("Xóa playlist", style: TextStyle(color: Colors.red)),
                ),
              ],
              onSelected: (value) async {
                if (value == "delete") {
                  handleDeletePlaylist(playlist["playlist_id"].toString());
                }

                if (value == "rename") {
                  showRenameBottomSheet(user!.id.toString(), playlist["playlist_id"].toString(), playlist["name"].toString());
                }
              },
            ),

            onTap: () async {
              final refresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(
                    playlistName: playlist["name"],
                    playlistId: playlist["playlist_id"].toString(),
                    userId: user!.id.toString(),
                  ),
                ),
              );

              if (refresh == true) {
                await playlistProvider.getUserPlaylists(user!.id.toString());
              }
            },
          );
        },
      ),
    );

  }
}