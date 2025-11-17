import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../home_screens/mini_player.dart';
import '../provider/audio_player_provider.dart';
import '../home_screens/just_audio_demo.dart';
import 'package:page_transition/page_transition.dart';

class GenreDetailScreen extends StatefulWidget {
  final String genreId;

  const GenreDetailScreen({
    required this.genreId,
    super.key,
  });

  @override
  GenreDetailScreenState createState() => GenreDetailScreenState();
}

class GenreDetailScreenState extends State<GenreDetailScreen> {
  bool hasChangedFavorite = false;
  bool isFavorite = false;
  int? currentIndex;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    fetchSongsByGenre(widget.genreId.toString());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  List<Map<String, dynamic>> songsByGenre = [];

  Future<void> fetchSongsByGenre(String genreId) async {
    final url = Uri.parse(
      "http://10.0.2.2:8081/music_API/online_music/song/get_songs_by_genre.php",
    );

    final response = await http.post(url, body: {
      "genre_id": genreId,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        setState(() {
          songsByGenre = List<Map<String, dynamic>>.from(data["songs"]);
        });
      }
    }
  }

  void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black.withOpacity(0.7),
      textColor: Colors.white,
      fontSize: 16,
    );
    Future.delayed(const Duration(seconds: 1), () {
      Fluttertoast.cancel();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(widget.genreId),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: AnimatedOpacity(
                    opacity: _scrollOffset > 100 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _getGenreName(widget.genreId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  background: _buildBanner(widget.genreId),
                ),
              ),

              // Songs list
              songsByGenre.isEmpty
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                    strokeWidth: 3,
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.only(bottom: 120, left: 8, right: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final song = songsByGenre[index];
                      return _buildSongTile(context, song, index);
                    },
                    childCount: songsByGenre.length,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Map<String, dynamic> song, int index) {
    final songTitle = song["title"] ?? "";
    final playCount = song["play_count"] ?? "";
    final coverUrl = song["cover_url"] ?? "";
    final artistName = song["artist_name"] ?? "Unknown Artist";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.white.withOpacity(0.1),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          songTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          artistName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onPressed: () {
          },
        ),
        onTap: () async {
          final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
          await audioProvider.setPlaylist(songsByGenre, startIndex: index);

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.bottomToTop,
                  child: const JustAudioDemo(),
                ),
              );
            },
            child: MiniPlayer(),
          );
        },
      ),
    );
  }

  Widget _buildBanner(String id) {
    final String title = _getGenreName(id);
    final List<Color> gradient = _getGradientColors(id).take(2).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
            top: 40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: 10,
            top: 50,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

          ),


          // Genre icon
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getGenreIcon(id),
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGenreName(String id) {
    final Map<int, String> genres = {
      25: "Việt Nam",
      15: "Nhạc Nhật",
      1: "Nhạc Âu",
      14: "Nhạc Hàn",
    };
    return genres[int.tryParse(id) ?? 25] ?? "Không rõ";
  }

  List<Color> _getGradientColors(String id) {
    final Map<int, List<Color>> colors = {
      25: [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F), const Color(0xFF121212)],
      15: [const Color(0xFFFFB347), const Color(0xFFFF8C42), const Color(0xFF121212)],
      1: [const Color(0xFF4FC3F7), const Color(0xFF29B6F6), const Color(0xFF121212)],
      14: [const Color(0xFFBA68C8), const Color(0xFFAB47BC), const Color(0xFF121212)],
    };
    return colors[int.tryParse(id) ?? 25] ?? [Colors.grey, Colors.black45, const Color(0xFF121212)];
  }

  IconData _getGenreIcon(String id) {
    final Map<int, IconData> icons = {
      25: Icons.flag,
      15: Icons.auto_awesome,
      1: Icons.language,
      14: Icons.stars,
    };
    return icons[int.tryParse(id) ?? 25] ?? Icons.music_note;
  }
}