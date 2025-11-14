import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/library_screens/playlist_detail_screen.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

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

  Future<void> createNewPlaylist(BuildContext context, Function(String) onCreated) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tạo playlist mới"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Nhập tên playlist"),
          ),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Tạo"),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final response = await http.post(
                  Uri.parse("http://10.0.2.2:8081/music_API/online_music/playlist/create_playlist.php"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "user_id": user!.id.toString(),
                    "name": name,
                  }),
                );

                final data = jsonDecode(response.body);
                if (data["status"] == "success") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tạo playlist thành công!")),
                  );
                  Navigator.pop(context);
                  onCreated(name);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data["message"] ?? "Lỗi khi tạo playlist")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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
        final songCount = songs.length;

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
