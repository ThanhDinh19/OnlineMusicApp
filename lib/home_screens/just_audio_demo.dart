import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../audio/music_wave.dart';
import '../handle_image/rotating_image.dart';
import '../provider/audio_player_provider.dart';
import '../provider/user_provider.dart';


class JustAudioDemo extends StatefulWidget {
  const JustAudioDemo({Key? key}): super(key: key);
  @override
  _JustAudioDemoState createState() => _JustAudioDemoState();
}

class _JustAudioDemoState extends State<JustAudioDemo> {
  double progress = 0.3;
  late AudioPlayerProvider _audioProvider;

  bool shuffleStatus = false;
  bool repeatStatus = false;
  Color shuffleColor = Colors.white;
  Color repeatColor = Colors.white;

  bool isFavorite = false;
  Color heartColor = Colors.white;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    final player = AudioPlayer();
    player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> toggleFavorite() async {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      isFavorite = !isFavorite;
      heartColor = isFavorite ? Colors.red : Colors.white;
    });

    final action = isFavorite ? "add" : "remove";
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/song/favorite_song.php");

    try {
      final res = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userProvider.user!.id.toString(),
            "song_id": audioProvider.currentSongId.toString(),
            "action": action
          }));

      final data = jsonDecode(res.body);
      print("API response: $data");

      if (data["status"] != "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ ${data["message"]}")),
        );
      }
    } catch (e) {
      print("Lỗi khi gửi yêu cầu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể kết nối đến server")),
      );
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/song/get_favorite_status.php?user_id=${userProvider.user!.id.toString()}&song_id=${audioProvider.currentSongId.toString()}"
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          isFavorite = data["status"] == true;
          heartColor = isFavorite ? Colors.red : Colors.white;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy trạng thái yêu thích: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final player = audioProvider.player;

    // cho bottom sheet
    String? currentCover = audioProvider.currentCover;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_down, size: 40),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          flexibleSpace: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: MusicWave(),
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(Icons.more_horiz),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent, // để thấy góc bo tròn
                  isScrollControlled: true, // cho phép kéo full màn hình
                  builder: (context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.4, // bắt đầu chiếm 30% chiều cao
                      minChildSize: 0.1,
                      maxChildSize: 0.9,
                      expand: false, // quan trọng để không chiếm hết màn hình
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF0F0F1C),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          child: ListView(
                            controller: scrollController,
                            children: [

                              ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: currentCover!.isNotEmpty && currentCover != null
                                      ? Image.network(
                                    currentCover,
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
                                title: Text(audioProvider.currentTitle ?? "Unkown"),
                                subtitle: Text(audioProvider.currentArtist ?? "Unkown"),
                              ),

                              Container(
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(width: 1, color: Colors.white24))
                                ),
                              ),

                              ListTile(
                                leading: Icon(Icons.share),
                                title: Text('Chia sẻ'),
                              ),
                              ListTile(
                                leading: Icon(Icons.add_circle_outline),
                                title: Text('Thêm vào danh sách phát'),
                              ),
                              ListTile(
                                leading: Icon(Icons.download),
                                title: Text('Tải xuống'),
                              ),
                              ListTile(
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
          ],

        ),


        body: Container(
          decoration: BoxDecoration(
            color: Color(0xFF44444E),
          ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(height: 110),

            // Ảnh bìa
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? false;

                return RotatingImage(
                  imagePath: audioProvider.currentCover ?? "",
                    isPlaying: playing,
                );
              },
            ),

            SizedBox(height: 120),

            // Tiêu đề & Nghệ sĩ
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                      onPressed: (){},
                      icon: FaIcon(FontAwesomeIcons.shareFromSquare, color: Colors.white,)
                  ),


                  SizedBox(
                    width: 280,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // tránh chiếm toàn bộ chiều cao
                      children: [
                        Text(
                          audioProvider.currentTitle ?? "Unknown",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                        Text(
                          audioProvider.currentArtist ?? "Unknown",
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: FaIcon(
                      isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                      color: heartColor,
                    ),
                    onPressed: toggleFavorite,
                  ),
                ],
              ),
            ),

            // Thanh tiến trình
            StreamBuilder<Duration>(
              stream: player.positionStream, // lắng nghe tiến trình
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;   // vị trí hiện tại
                final duration = player.duration ?? Duration.zero; // tổng thời lượng bài hát

                double pos = position.inSeconds.toDouble();
                double max = duration.inSeconds.toDouble();

                // Nếu pos > max thì gán bằng max
                if (pos > max) pos = max;

                return Column(
                  children: [
                    Slider(
                      value: pos,
                      max: max > 0 ? max : 1.0,
                      onChanged: (value) {
                        player.seek(Duration(seconds: value.toInt()));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Thời gian hiện tại
                          Text(
                            _formatDuration(position),
                            style: TextStyle(color: Colors.white),
                          ),
                          // Tổng thời lượng
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              },
            ),
            // Nút điều khiển
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                // nút shuffle
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.shuffle,
                    color: audioProvider.isShuffle ? const Color(0xFF26355D) : Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    audioProvider.toggleShuffle();
                  },
                ),

                IconButton(
                  icon: FaIcon(FontAwesomeIcons.backwardStep, color: Colors.white, size: 40),
                  onPressed: ()=>audioProvider.playPrevious(),
                ),

                StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snapshot){

                      final state = snapshot.data;

                      if (state == null) {
                        return FaIcon(FontAwesomeIcons.circlePlay, size: 70, color: Colors.white);
                      }

                      final playing = state?.playing ?? false;
                      // Nếu đã phát xong
                      if (state.processingState == ProcessingState.completed) {
                        // reset về đầu bài
                        player.seek(Duration.zero);
                        player.stop();
                        return IconButton(
                          icon:FaIcon(FontAwesomeIcons.circlePlay, size: 70, color: Colors.white,),
                          onPressed: ()=>audioProvider.playPrevious(),
                        );
                      }

                      if(playing){
                        return IconButton(
                          icon: FaIcon(FontAwesomeIcons.circlePause, size: 70, color: Colors.white,),
                          onPressed: ()=>player.pause(),
                        );
                      }
                      else{
                        return IconButton(
                          icon:FaIcon(FontAwesomeIcons.circlePlay, size: 70, color: Colors.white,),
                          onPressed: ()=>player.play(),
                        );
                      }
                    }
                ),

                IconButton(
                  icon: FaIcon(FontAwesomeIcons.forwardStep, color: Colors.white, size: 40),
                  onPressed: ()=>audioProvider.playNext(),
                ),

                // nút repeat
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.repeat,
                    color: audioProvider.isRepeat ? const Color(0xFF26355D) : Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    audioProvider.toggleRepeat();
                  },
                ),
              ],
            )
          ],
        ),
      )
    );
  }
}
