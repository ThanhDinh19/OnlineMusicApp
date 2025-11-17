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
    if (user != null) getUserPlaylists(user.id.toString());
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

  Future<void> createNewPlaylist(BuildContext context, Function(String) onCreated) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    // Auto focus vào TextField
    Future.delayed(const Duration(milliseconds: 100), () {
      focusNode.requestFocus();
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF2A2A2A),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.playlist_add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tạo Playlist Mới",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Đặt tên cho playlist của bạn",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      // TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLength: 50,
                          decoration: InputDecoration(
                            hintText: "Ví dụ: Nhạc yêu thích của tôi",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.music_note_rounded,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            counterText: "",
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          // Cancel button
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.white.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "Hủy",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Create button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final name = controller.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text("Vui lòng nhập tên playlist"),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: Color(0xFF6366F1),
                                            strokeWidth: 3,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            "Đang tạo playlist...",
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                try {
                                  final response = await http.post(
                                    Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/create_playlist.php"),
                                    headers: {"Content-Type": "application/json"},
                                    body: jsonEncode({
                                      "user_id": user!.id.toString(),
                                      "name": name,
                                    }),
                                  );

                                  final data = jsonDecode(response.body);

                                  // Close loading dialog
                                  Navigator.pop(context);

                                  if (data["status"] == "success") {
                                    // Close create dialog
                                    Navigator.pop(context);

                                    showToast("Đã tạo playlist");

                                    onCreated(name);
                                  } else {
                                    showToast("Lỗi khi tạo playlist");
                                  }
                                } catch (e) {
                                  // Close loading dialog
                                  Navigator.pop(context);

                                  showToast("Lỗi kết nối mạng");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Tạo Playlist",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      controller.dispose();
      focusNode.dispose();
    });
  }

  Future<void> getUserPlaylists(String userId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/get_user_playlists.php?user_id=$userId");
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
                  await getUserPlaylists(user!.id.toString());
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
              await getUserPlaylists(user!.id.toString());
            }
          },
        );
      },
    );
  }
}
