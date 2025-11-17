import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/library_screens/playlist.dart';
import 'package:music_app/provider/audio_player_provider.dart';
import 'package:music_app/provider/favorite_song_provider.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '../home_screens/just_audio_demo.dart';
import '../home_screens/mini_player.dart';
import '../provider/favorite_album_provider.dart';
import '../search_screen/album_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  //List<Map<String, dynamic>> favorite_songs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final user = Provider.of<UserProvider>(context, listen: false).user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = user!.id.toString();

      Provider.of<FavoriteAlbumProvider>(context, listen: false)
          .loadAlbumFavorites(uid);

      Provider.of<FavoriteSongProvider>(context, listen: false)
          .loadSongFavorites(uid);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user!.id.toString();
    Provider.of<FavoriteAlbumProvider>(context, listen: false)
        .loadAlbumFavorites(uid);
    Provider.of<FavoriteSongProvider>(context, listen: false)
        .loadSongFavorites(uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50), // tổng chiều cao của AppBar + TabBar
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 40,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.indigoAccent,
            labelColor: Colors.indigoAccent,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "Đã tải"),
              Tab(text: "Playlist"),
              Tab(text: "Album"),
              Tab(text: "Yêu thích"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DownloadedTab(userId: user!.id.toString()),
          Playlist(),
          _buildListAlbumTab(),
          _buildFavoriteTab(),
        ],
      ),


    );
  }

  // Tab 3: Album
  Widget _buildListAlbumTab() {
    final favoriteProvider = Provider.of<FavoriteAlbumProvider>(context);
    final albums = favoriteProvider.albums;

    if (albums.isEmpty) {
      return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.album_outlined, size: 50,),
              SizedBox(height: 20),
              Text(
                "Bạn chưa có album nào",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Hãy tìm kiếm album bạn yêu thích để thêm vào",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final item = albums[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item['cover_url'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            title: Text(
              item['name'] ?? "Chưa có tên",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              item['description'] ?? "Không có mô tả",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(
                    albumId: item['album_id'].toString(),
                    albumName: item['name'],
                    albumCover: item['cover_url'],
                  ),
                  settings: const RouteSettings(name: "albumScreen"),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Tab 4: Yêu thích
  Widget _buildFavoriteTab() {
    final favoriteProvider = Provider.of<FavoriteSongProvider>(context);
    final favoriteSongs = favoriteProvider.songs;
    return favoriteSongs.isEmpty ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 50,),
            SizedBox(height: 20),
            Text(
              "Chưa có bài hát yêu thích",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "Hãy tìm kiếm bài hát bạn yêu thích để thêm vào",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
    ) :
    ListView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = favoriteSongs[index];
        final songId = song["song_id"].toString() ?? "";
        final title = song["title"] ?? "Unknown Title";
        final artist = song["artist_name"] ?? "Unknown Artist";
        final audioUrl = song["audio_url"] ?? "";
        final duration = song["duration"] ?? "";
        final coverUrl = song["cover_url"] ?? "";
        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                coverUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(artist,
                style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.more_vert, color: Colors.white70),
            onTap: () async {
              final audioProvider = Provider.of<AudioPlayerProvider>(
                  context, listen: false);

              // Gọi API để lấy toàn bộ danh sách
              List<Map<String, dynamic>> songsList = favoriteSongs;

              // Set playlist & bài hiện tại
              await audioProvider.setPlaylist(songsList, startIndex: index,);

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

}

class DownloadedTab extends StatefulWidget {
  final String userId;
  const DownloadedTab({required this.userId});

  @override
  State<DownloadedTab> createState() => _DownloadedTabState();
}

class _DownloadedTabState extends State<DownloadedTab> {
  List<Map<String, dynamic>> downloadedSongs = [];
  final AudioPlayer player = AudioPlayer();

  bool isLoading = true;
  int? currentIndex; // để biết bài nào đang phát
  @override
  void initState() {
    super.initState();
    loadDownloadedSongs();
  }

  Future<List<Map<String, dynamic>>> fetchOfflineSongs(String userId) async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/download/get_downloaded_songs.php?user_id=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        return List<Map<String, dynamic>>.from(data["songs"]);
      }
    }
    return [];
  }

  Future<void> loadDownloadedSongs() async {
    final songs = await fetchOfflineSongs(widget.userId);
    setState(() {
      downloadedSongs = songs;
      if(downloadedSongs.isNotEmpty){
        isLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    return isLoading
        ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_circle_down, size: 50,),
            SizedBox(height: 20),
            Text(
              "Chưa có bài hát tải xuống",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
    )
        : ListView.builder(
      shrinkWrap: true, // Giới hạn chiều cao theo nội dung
      physics: const NeverScrollableScrollPhysics(), // Tắt cuộn bên trong
      itemCount: downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = downloadedSongs[index];
        final songId = song["song_id"].toString() ?? "";
        final title = song["title"] ?? "Unknown Title";
        final artist = song["artist"] ?? "Unknown Artist";
        final audioLocalFile = song["local_path"] ?? "";
        final coverUrl = song["cover_url"] ?? "";

        return ListTile(
          leading: coverUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              coverUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  currentIndex == index
                      ? Icons.play_circle_fill
                      : Icons.music_note,
                  color:
                  currentIndex == index ? Colors.green : null,
                  size: 40,
                );
              },
            ),
          )
              : Icon(
            currentIndex == index
                ? Icons.play_circle_fill
                : Icons.music_note,
            color: currentIndex == index ? Colors.green : null,
            size: 40,
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle:
          Text(
            artist,
            style: const TextStyle(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
                              title: Text(title),
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
                              onTap: ()  {
                              },
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

            // Gọi API để lấy toàn bộ danh sách
            List<Map<String, dynamic>> songsList = downloadedSongs;

            // Set playlist & bài hiện tại
            await audioProvider.setOfflinePlaylist(songsList, startIndex: index,);

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
}



