
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../handle_image/rotating_image_1.dart';
import '../provider/audio_player_provider.dart';


class MiniPlayer extends StatefulWidget {
  @override
  MiniPlayerState createState() => MiniPlayerState();
}

class MiniPlayerState extends State<MiniPlayer> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final player = audioProvider.player;


    // mới đăng ký vào hoặc mới đăng xuất sau đó đăng nhập lại thì k hiển thị
    if (audioProvider.currentSongPath == null ||
        audioProvider.currentSongPath!.isEmpty ||
        audioProvider.currentTitle == null ||
        audioProvider.currentTitle!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [Color(0xFF26355D), Color(0xFFA0153E)],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        color: Color(0xFF44444E),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Ảnh cover
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              return RotatingImage_1(
                imagePath: audioProvider.currentCover?.trim().isNotEmpty == true
                    ? audioProvider.currentCover!
                    : 'assets/images/default_cover.png',
                isPlaying: player.playing,
              );
            },
          ),

          SizedBox(width: 12),

          // Title + Artist
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audioProvider.currentTitle ?? "No song",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  audioProvider.currentArtist ?? "",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Các nút điều khiển
          Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton(
                    icon: FaIcon(
                      playing
                          ? FontAwesomeIcons.circlePause
                          : FontAwesomeIcons.circlePlay,
                      color: Colors.white,
                      size: 33,
                    ),
                    onPressed: () {
                      if (playing) {
                        player.pause();
                        audioProvider.setPlaying(false);
                      } else {
                        player.play();
                        audioProvider.setPlaying(true);
                      }
                    },
                  );
                },
              ),
              IconButton(
                onPressed: () => audioProvider.playNext(),
                icon: FaIcon(
                  FontAwesomeIcons.forwardStep,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
