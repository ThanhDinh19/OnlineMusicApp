import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/library_screens/playlist_detail_screen.dart';
import 'package:music_app/provider/load_song_provider.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class Playlist extends StatefulWidget {
  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  @override
  void initState() {
    super.initState();

    /// Chỉ gọi API sau khi widget đã build context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        await Provider.of<LoadSongProvider>(context, listen: false)
            .getUserPlaylists(user.id.toString());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user!.id.toString();
    Provider.of<LoadSongProvider>(context, listen: false)
        .getUserPlaylists(user.id.toString());
  }
  // Toast gọn
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

  // API tạo playlist
  Future handleNewPlaylist(BuildContext context, String name) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      showToast("Vui lòng đăng nhập");
      return;
    }

    final response = await http.post(
      Uri.parse(
          "http://10.0.2.2:8081/music_API/online_music/playlist/create_playlist.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": user.id, "name": name}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        debugPrint("Playlist created");
      } else {
        showToast("Không thể tạo playlist");
      }
    } else {
      showToast("Lỗi kết nối mạng");
    }
  }

  // UI tạo playlist
  Future createNewPlaylist(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E201E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Đặt tên cho playlist của bạn",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: controller,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Tên playlist...",
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Hủy",
                            style: TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 14),
                          ),
                          onPressed: () async {
                            final name = controller.text.trim();

                            if (name.isEmpty) {
                              showToast("Hãy nhập tên playlist");
                              return;
                            }

                            await handleNewPlaylist(context, name);

                            await Provider.of<LoadSongProvider>(context,
                                listen: false)
                                .getUserPlaylists(user.id.toString());

                            showToast("Đã tạo playlist");

                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Tạo",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
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


  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    /// Lấy playlist TỰ ĐỘNG rebuild khi provider notifyListeners()
    final playlistProvider = Provider.of<LoadSongProvider>(context);
    final playlists = playlistProvider.playlists;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        // Nút "Tạo playlist"
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => createNewPlaylist(context),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [Colors.white10, Colors.white12],
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey, size: 30),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Tạo danh sách phát",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        // Playlist item
        final playlist = playlists[index - 1];
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
    );
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


}
