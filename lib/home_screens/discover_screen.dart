// have been used
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../provider/audio_player_provider.dart';
import '../provider/user_provider.dart';
import '../search_screen/album_detail_screen.dart';
import 'just_audio_demo.dart';
import 'mini_player.dart';

class DiscoverScreen extends StatefulWidget{
  const DiscoverScreen({Key? key}) : super(key: key);
  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {

  List<dynamic> albums = [];
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    fetchAlbums();
    fetchStarterSongs();
    fetchRecommendedSongs();
  }


  // fetch favorite albums for new account
  Future<void> fetchAlbums() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/artist/get_albums_by_favorite_artists.php?user_id=${user!.id.toString()}");

    final res = await http.get(url);
    debugPrint("Response: ${res.body}");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        setState(() {
          albums = data["albums"];
          isLoading = false;
        });
        print("==========================================================================");
        print(albums);
        debugPrint("Tải ${albums.length} album");
      } else {
        debugPrint("Dữ liệu không hợp lệ: ${data["message"]}");
      }
    } else {
      debugPrint("Lỗi server: ${res.statusCode}");
    }
  }

  List<Map<String, dynamic>> recommendedSongs = [];
  List<Map<String, dynamic>> starterSongs = [];

  Future<void> fetchRecommendedSongs() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/recommendation/recommendations.php?user_id=$userId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        if (data["recommendations"] == null || data["recommendations"].isEmpty) {
          debugPrint("🟡 Chưa có lịch sử nghe → tải gợi ý cho người mới");
          await fetchStarterSongs();
        } else {
          setState(() {
            recommendedSongs = List<Map<String, dynamic>>.from(data["recommendations"]);
          });
        }
      }
    }
  }

  /// API fallback: Gợi ý cho người mới
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

  // đếm số lượng nhạc được nghe
  Future<void> increasePlayCount(String songId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/song/update_play_count.php");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"song_id": songId}),
      );

      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        print("🎧 Play count updated: ${data["play_count"]}");
      } else {
        print("⚠️ Lỗi cập nhật lượt nghe: ${data["message"]}");
      }
    } catch (e) {
      print("Lỗi khi gọi API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Để bạn bắt đầu
            const Text(
              'Để bạn bắt đầu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            isLoading ? const Center(child: CircularProgressIndicator(color: Colors.blue)) :
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final item = albums[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12), // bo góc khi click
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlbumDetailScreen(
                              albumId: item['album_id'].toString(),
                              albumName: item['album_name'],
                              albumCover: item['cover_url'],
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item['cover_url'] ?? '',
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Background nửa mờ
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.black.withOpacity(0.1),
                                ),
                              ),
                              // Text ở giữa ảnh
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                margin:  EdgeInsets.only(left: 60,top: 90),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: const Text(
                                  'Album',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['album_name'] ?? "Unknown",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Dành riêng cho bạn
            if(recommendedSongs.isEmpty && starterSongs.isNotEmpty)...[
              const Text(
                'Gợi ý cho bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230, // đủ cao để chứa 3 bài (ảnh + text)
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (starterSongs.length / 3).ceil(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, columnIndex) {
                    final start = columnIndex * 3;
                    final end = (start + 3 < starterSongs.length)
                        ? start + 3
                        : starterSongs.length;
                    final columnSongs = starterSongs.sublist(start, end);

                    return Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 330,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(columnSongs.length, (i) {
                          final song = columnSongs[i];
                          final globalIndex = start + i;

                          return Padding(
                            padding: EdgeInsets.zero,
                              child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      song["cover_url"] ?? "",
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ),

                                  title: Text(
                                    song["title"] ?? "Không rõ tên bài hát",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                 subtitle: Text(
                                    song["artist_name"] ?? "Không rõ nghệ sĩ",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                 ),
                                trailing: IconButton(icon: Icon(Icons.more_horiz,),
                                  onPressed: (){

                                  },
                                ),
                                onTap: () async {
                                  final audioProvider = Provider.of<AudioPlayerProvider>(
                                    context,
                                    listen: false,
                                  );

                                  await audioProvider.setPlaylist(starterSongs, startIndex: globalIndex,);

                                  await increasePlayCount(audioProvider.currentSongId.toString(),);

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
                        }),
                      ),
                    );
                  },
                ),
              ),
            ]
            else if( recommendedSongs.isNotEmpty)...[
              const Text(
                'Dành riêng cho bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230, // đủ chứa 3 bài
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (recommendedSongs.length / 3).ceil(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, columnIndex) {
                    final start = columnIndex * 3;
                    final end = (start + 3 < recommendedSongs.length)
                        ? start + 3
                        : recommendedSongs.length;
                    final columnSongs = recommendedSongs.sublist(start, end);

                    return Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 330,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(columnSongs.length, (i) {
                          final song = columnSongs[i];
                          final globalIndex = start + i;

                          return Padding(
                            padding: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    song["cover_url"] ?? "",
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.music_note,
                                            color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                title: Text(
                                  song["title"] ?? "Không rõ tên bài hát",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  song["artist_name"] ?? "Không rõ nghệ sĩ",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: IconButton(icon: Icon(Icons.more_horiz,),
                                  onPressed: (){

                                  },
                                ),
                                onTap: () async {
                                  final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

                                  await audioProvider.setPlaylist(recommendedSongs, startIndex: globalIndex,);

                                  await increasePlayCount(audioProvider.currentSongId.toString());

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
                        }),
                      ),
                    );
                  },
                ),
              ),
            ]
            else...[
              const Center(
                child: Text(
                  "Không có dữ liệu gợi ý",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],


            // Gợi ý bài hát
            const Text(
              'Nội dung hay nghe gần đây',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(
                3,
                    (index) => ListTile(
                      contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/album${index + 1}.jpg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const Text(
                    'Tên album',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tên nghệ sĩ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Album mới
            const Text(
              'Album mới phát hành',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(
                3,
                    (index) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/album${index + 1}.jpg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const Text(
                    'Tên album',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tên nghệ sĩ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),


      bottomNavigationBar: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.bottomToTop,
              child: JustAudioDemo(),
            ),
          );
        },
        child:  MiniPlayer(),
      ),

    );
  }
}
