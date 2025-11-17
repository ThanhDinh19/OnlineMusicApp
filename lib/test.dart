import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/design/EqualizerAnimation.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../home_screens/just_audio_demo.dart';
import '../home_screens/mini_player.dart';
import '../provider/audio_player_provider.dart';
import '../provider/user_provider.dart';

class PlaylistDetailTestScreen extends StatefulWidget {
  final String playlistName;
  final String playlistId;
  final String userId;

  const PlaylistDetailTestScreen({
    super.key,
    required this.userId,
    required this.playlistName,
    required this.playlistId,
  });

  @override
  State<PlaylistDetailTestScreen> createState() => _PlaylistDetailTestScreenState();
}

class _PlaylistDetailTestScreenState extends State<PlaylistDetailTestScreen> {
  String playlistName = "";
  bool playStatus = false;
  bool repeatStatus = true;

  List<Map<String, dynamic>> topSongs = [];
  List<Map<String, dynamic>> playlistOnlineSongs = [];
  bool isLoading = true;
  bool loading = true;
  int? currentIndex;

  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> starterSongs = [];
  List<Map<String, dynamic>> onlinePlaylists = [];
  List<Map<String, dynamic>> onlineSongs = [];
  List<bool> selectedPlaylists = [];

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

  // [Giữ nguyên tất cả các hàm API và logic của bạn]
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
      }
    }
  }

  Future<void> getUserPlaylists() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    final uId = userProvider!.id.toString();
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/playlist/get_user_playlists.php?user_id=$uId");
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

  Future<List<Map<String, dynamic>>> fetchOnlineSongs() async {
    try {
      final url = Uri.parse(
          "http://10.0.2.2:8081/music_API/online_music/song/get_songs.php");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse["status"] == true && jsonResponse["songs"] != null) {
          final List songs = jsonResponse["songs"];
          setState(() {
            onlineSongs = List<Map<String, dynamic>>.from(songs);
            isLoading = false;
          });
          return onlineSongs;
        }
      }
    } catch (e) {
      print("Error: $e");
    }
    return [];
  }

  Future<void> addToPlaylist(String songId, String userId, String playlistId) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/playlist/add_to_playlist.php");
    final body = json.encode({
      "user_id": userId,
      "playlist_id": playlistId,
      "song_id": songId
    });
    await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
    await getPlaylistSongs(userId, widget.playlistId);
  }

  Future<void> removeFromPlaylist(String songId, String userId, String playlistId) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/playlist/remove_song_from_playlist.php");
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
      }
    }
  }

  void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black45.withOpacity(0.6),
      textColor: Colors.white,
      fontSize: 16.0,
    );
    Future.delayed(Duration(seconds: 1), () {
      Fluttertoast.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
              padding: EdgeInsets.zero,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2C3E50),
                Color(0xFF1a1a2e),
                Color(0xFF0f0f1e),
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildPlaylistHeader(context, audioProvider),
              ),
              SliverToBoxAdapter(
                child: _buildActionButtons(context),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: _buildSongListInPlayList(context, audioProvider),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildRecommendSection(context),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistHeader(BuildContext context, AudioPlayerProvider audioProvider) {
    final songs = playlistOnlineSongs;

    Widget bannerContent;
    if (songs.length >= 4) {
      bannerContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Image.network(
              song["cover_url"] ?? "",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade800,
                child: Icon(Icons.music_note, color: Colors.white38),
              ),
            );
          },
        ),
      );
    } else if (songs.isNotEmpty) {
      bannerContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          songs[0]["cover_url"] ?? "",
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade800,
            child: Icon(Icons.library_music, color: Colors.white38, size: 80),
          ),
        ),
      );
    } else {
      bannerContent = Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.library_music, color: Colors.white38, size: 80),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24, 100, 24, 20),
      child: Column(
        children: [
          // Cover Image với shadow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: bannerContent,
          ),

          SizedBox(height: 24),

          // Playlist Title
          Text(
            audioProvider.playlistName.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 8),

          // Song count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${songs.length} bài hát",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Play Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shuffle Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.shuffle,
                    color: audioProvider.isShuffle
                        ? Color(0xFF1DB954)
                        : Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => setState(() => audioProvider.toggleShuffle()),
                ),
              ),

              SizedBox(width: 20),

              // Main Play Button
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ed760)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF1DB954).withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    audioProvider.isPlaying && audioProvider.playlistId == widget.playlistId
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  onPressed: () async {
                    if (audioProvider.playlistId != widget.playlistId &&
                        audioProvider.playlist.isNotEmpty) {
                      await audioProvider.setPlaylist(
                          playlistOnlineSongs,
                          startIndex: audioProvider.currentIndex
                      );
                      audioProvider.setPlaying(true);
                      audioProvider.playlistId = widget.playlistId;
                    } else {
                      audioProvider.playlistId = widget.playlistId;
                      if (audioProvider.playlist.isEmpty) {
                        await audioProvider.setPlaylist(
                            playlistOnlineSongs,
                            startIndex: 0
                        );
                        audioProvider.player.play();
                        audioProvider.setPlaying(true);
                      } else {
                        audioProvider.isPlaying
                            ? audioProvider.player.pause()
                            : audioProvider.player.play();
                        audioProvider.setPlaying(!audioProvider.isPlaying);
                      }
                    }
                  },
                ),
              ),

              SizedBox(width: 20),

              // More Options Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.white70),
                  onPressed: () => _playlistInfomation(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.add_rounded,
              label: 'Thêm',
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              onTap: () => _searchSongs(context),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.edit_outlined,
              label: 'Chỉnh sửa',
              gradient: LinearGradient(
                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
              ),
              onTap: () => _editPlaylist(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongListInPlayList(BuildContext context, AudioPlayerProvider audioProvider) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    if (playlistOnlineSongs.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.music_note_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Chưa có bài hát nào',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: playlistOnlineSongs.length,
      itemBuilder: (context, index) {
        final song = playlistOnlineSongs[index];
        final isPlaying = audioProvider.currentIndex == index &&
            audioProvider.playlistId == widget.playlistId;

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isPlaying
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song['cover_url'] != null
                      ? Image.network(
                    song['cover_url'],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade800,
                    child: Icon(Icons.music_note, color: Colors.white38),
                  ),
                ),
                if (isPlaying && audioProvider.isPlaying)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: EqualizerAnimation(isPlaying: true),
                    ),
                  ),
              ],
            ),
            title: Text(
              song['title'] ?? 'Unknown',
              style: TextStyle(
                color: isPlaying ? Color(0xFF1DB954) : Colors.white,
                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song['artist_name'] ?? 'Unknown Artist',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white54),
              onPressed: () => _showSongOptions(context, song, index),
            ),
            onTap: () async {
              await audioProvider.setPlaylist(
                playlistOnlineSongs,
                startIndex: index,
                statusIndex: 1,
              );
              audioProvider.setCurrentSong(index);
              audioProvider.setPlaying(true);
              audioProvider.playlistId = widget.playlistId;
            },
          ),
        );
      },
    );
  }

  Widget _buildRecommendSection(BuildContext context) {
    if (starterSongs.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            "Đề xuất cho bạn",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildRecommendSongList(context),
      ],
    );
  }

  Widget _buildRecommendSongList(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: starterSongs.length > 10 ? 10 : starterSongs.length,
      itemBuilder: (context, index) {
        final song = starterSongs[index];

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song['cover_url'] != null
                  ? Image.network(
                song['cover_url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade800,
                child: Icon(Icons.music_note, color: Colors.white38),
              ),
            ),
            title: Text(
              song['title'] ?? 'Unknown',
              style: TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song['artist_name'] ?? 'Unknown Artist',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(Icons.add_circle_outline, color: Color(0xFF1DB954)),
              onPressed: () async {
                await addToPlaylist(
                  song['song_id'].toString(),
                  user!.id.toString(),
                  widget.playlistId,
                );
                showSuccessToast("Đã thêm vào playlist");
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, Map<String, dynamic> song, int index) {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                title: Text('Xóa khỏi playlist', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await removeFromPlaylist(
                    song['song_id'].toString(),
                    user!.id.toString(),
                    widget.playlistId,
                  );
                  await getPlaylistSongs(user.id.toString(), widget.playlistId);
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.white70),
                title: Text('Chia sẻ', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // Giữ nguyên các hàm _searchSongs, _editPlaylist, _playlistInfomation của bạn
  void _searchSongs(BuildContext context) {
    // Implementation của bạn
  }

  void _editPlaylist(BuildContext context) {
    // Implementation của bạn
  }

  void _playlistInfomation(BuildContext context) {
    // Implementation của bạn
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}