import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../audio/music_wave.dart';
import '../design/EqualizerAnimation.dart';
import '../handle_image/rotating_image.dart';
import '../provider/audio_player_provider.dart';
import '../provider/favorite_song_provider.dart';
import '../provider/user_provider.dart';

class JustAudioDemo extends StatefulWidget {
  const JustAudioDemo({Key? key}) : super(key: key);

  @override
  _JustAudioDemoState createState() => _JustAudioDemoState();
}

class _JustAudioDemoState extends State<JustAudioDemo> {
  late AudioPlayerProvider _audioProvider;

  Color dominantColor = Colors.grey;
  bool isFavorite = false;
  bool hasChangedFavorite = false;

  @override
  void initState() {
    super.initState();

    _audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    // kiểm tra trạng thái favorite album
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? "";

    if (userId.isNotEmpty) {
      checkFavoriteStatus();
      hasChangedFavorite = false; // ban đầu chưa thay đổi gì
    }

    // Lấy màu từ ảnh bìa khi mở screen
    if (_audioProvider.currentCover != null &&
        _audioProvider.currentCover!.isNotEmpty) {
      updateBackgroundColor(_audioProvider.currentCover!);
    }

    // Lấy màu khi bài hát đổi
    _audioProvider.player.currentIndexStream.listen((index) async {
      if (index == null) return;

      // update UI bài mới
      setState(() {});

      // cập nhật màu nền
      final cover = _audioProvider.currentCover;
      if (cover != null && cover.isNotEmpty) {
        updateBackgroundColor(cover);
      }

      // cập nhật trái tim
      await checkFavoriteStatus();

      // báo UI khác cập nhật
      _audioProvider.setPlaying(_audioProvider.player.playing);
    });

  }

  //  LẤY MÀU TỪ ẢNH
  Future<void> updateBackgroundColor(String imageUrl) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
      );
      setState(() {
        dominantColor = palette.dominantColor?.color ?? Colors.grey;
      });
    } catch (e) {
      print("Lỗi lấy màu chủ đạo: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  // API: Toggle favorite
  Future<void> toggleFavorite() async {
    final audioProvider = _audioProvider;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      isFavorite = !isFavorite;
    });

    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/song/favorite_song.php");

    try {
      final res = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userProvider.user!.id.toString(),
            "song_id": audioProvider.currentSongId.toString(),
            "action": isFavorite ? "add" : "remove"
          }));

      final data = jsonDecode(res.body);
      print("API Favorite: $data");
    } catch (e) {
      print("Lỗi favorite: $e");
    }
  }

  // Load trạng thái favorite
  Future<void> checkFavoriteStatus() async {
    final audioProvider = _audioProvider;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/song/get_favorite_status.php"
            "?user_id=${userProvider.user!.id}&song_id=${audioProvider.currentSongId}");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if(data["status"] == true){
          setState(() {
            isFavorite = true;
          });
        }else {
          setState(() {
            isFavorite = false;
          });
        }
      }
    } catch (_) {
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

    // Tuỳ chọn: tự tắt sớm hơn (nếu muốn)
    Future.delayed(const Duration(seconds: 1), () {
      Fluttertoast.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final player = audioProvider.player;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      //  APPBAR
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 40),
          onPressed: () => Navigator.pop(context, hasChangedFavorite),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: MusicWave()),
        ),
      ),


      //  BACKGROUND ĐỘNG THEO ẢNH
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dominantColor.withOpacity(0.9),
              dominantColor.withOpacity(0.5),
            ],
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 110),

            // ẢNH XOAY
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (_, snapshot) {
                final playing = snapshot.data?.playing ?? false;

                return RotatingImage(
                  imagePath: audioProvider.currentCover ?? "",
                  isPlaying: playing,
                );
              },
            ),

            const SizedBox(height: 120),

            // TÊN BÀI & NGHỆ SĨ + NÚT TIM
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Icon(Icons.share, color: Colors.white),

                SizedBox(
                  width: 260,
                  child: Column(
                    children: [
                      Text(
                        audioProvider.currentTitle ?? "Unknown",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        audioProvider.currentArtist ?? "Unknown",
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),

                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                    size: 30,
                  ),
                  onPressed: () async {

                    if(user == null){
                      showToast("Hãy đăng nhập tài khoản để trải ngiệm\n âm nhạc tuyệt vời hơn");
                      return;
                    }

                    setState(() {
                      isFavorite = !isFavorite;
                    });
                    final songData = audioProvider.playlist[audioProvider.currentIndex];
                    final favProvider = Provider.of<FavoriteSongProvider>(context, listen: false);
                    await favProvider.toggleSongFavorite(userProvider.user!.id.toString(), audioProvider.currentSongId.toString(), isFavorite, songData);
                  },
                ),
              ],
            ),

            // SLIDER PROGRESS
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snap) {
                final pos = snap.data ?? Duration.zero;
                final dur = player.duration ?? Duration.zero;

                double p = pos.inSeconds.toDouble();
                double m = dur.inSeconds.toDouble();
                if (p > m) p = m;

                return Column(
                  children: [
                    Slider(
                      value: p,
                      max: m == 0 ? 1 : m,
                      onChanged: (value) {
                        player.seek(Duration(seconds: value.toInt()));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(pos),
                              style: const TextStyle(color: Colors.white)),
                          Text(_formatDuration(dur),
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.shuffle,
                    color: audioProvider.isShuffle
                        ? Colors.yellow
                        : Colors.white,
                  ),
                  onPressed: audioProvider.toggleShuffle,
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.backwardStep,
                      color: Colors.white, size: 40),
                  onPressed: audioProvider.playPrevious,
                ),
                StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (_, snapshot) {
                      final state = snapshot.data;
                      final playing = state?.playing ?? false;

                      if (state?.processingState ==
                          ProcessingState.completed) {
                        player.seek(Duration.zero);
                        player.pause();
                      }

                      return IconButton(
                        icon: FaIcon(
                          playing
                              ? FontAwesomeIcons.circlePause
                              : FontAwesomeIcons.circlePlay,
                          size: 70,
                          color: Colors.white,
                        ),
                          onPressed: () {
                            if (playing) {
                              player.pause();
                              audioProvider.setPlaying(false); // ← thêm dòng này
                            } else {
                              player.play();
                              audioProvider.setPlaying(true); // ← thêm dòng này
                            }
                          },
                      );
                    }),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.forwardStep,
                      color: Colors.white, size: 40),
                  onPressed: audioProvider.playNext,
                ),
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.repeat,
                    color: audioProvider.isRepeat
                        ? Colors.yellow
                        : Colors.white,
                  ),
                  onPressed: audioProvider.toggleRepeat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
