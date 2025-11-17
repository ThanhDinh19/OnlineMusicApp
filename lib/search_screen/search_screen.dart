import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/search_screen/album_detail_screen.dart';

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
  bool isLoading = false;

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
            data["songs"] is List) {
          setState(() {
            albums = List.from(data["albums"]);
            songs = List.from(data["songs"]);
          });
        } else {
          print("Dữ liệu không hợp lệ: $data");
          setState(() {
            albums = [];
            songs = [];
          });
        }
      }
      else {
        debugPrint("Lỗi HTTP ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi khi tìm kiếm: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    searchAll("");
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = albums.isNotEmpty || songs.isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            //  Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 60, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm bài hát, nghệ sĩ hoặc album...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: searchAll,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => searchAll(_searchController.text),
                  ),
                ],
              ),
            ),

            //  Danh sách kết quả
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : !hasResults
                  ? Center(
                child: Text(
                  _searchController.text.isEmpty
                      ? "Nhập từ khóa để tìm kiếm"
                      : "Không tìm thấy kết quả",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16),
                ),
              )
                  : ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                children: [
                  // --- ALBUMS ---
                  if (albums.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Albums",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...albums.map((album) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AlbumDetailScreen(
                                  albumId: album["album_id"],
                                  albumName: album["name"],
                                  albumCover: album["cover_url"] ??
                                      "http://10.0.2.2:8081/music_API/online_music/album/album_cover/default.png",
                                ),
                            settings: const RouteSettings(name: "albumScreen"),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            album["cover_url"] ??
                                "http://10.0.2.2:8081/music_API/online_music/album/album_cover/default.png",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(album["name"] ?? "",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            album["description"] ??
                                album["artist"] ??
                                "",
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white54),
                      ),
                    )),
                  ],

                  // --- SONGS ---
                  if (songs.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("🎵 Bài hát",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...songs.map((song) => ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          song["cover_url"] ??
                              "http://10.0.2.2:8081/music_API/online_music/cover/default.png",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(song["title"] ?? "",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(song["artist"] ?? "",
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13)),
                      trailing: const Icon(Icons.play_arrow,
                          color: Colors.white54),
                      onTap: () {
                        // ở đây bạn mở player hoặc SongDetailScreen
                      },
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
