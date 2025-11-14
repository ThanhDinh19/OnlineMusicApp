import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import '../handle_image/rotating_image_1.dart';
import '../provider/audio_player_provider.dart';

class MiniPlayer extends StatefulWidget {
  @override
  MiniPlayerState createState() => MiniPlayerState();
}

class MiniPlayerState extends State<MiniPlayer> {
  late AudioPlayerProvider _audioProvider;
  Color dominantColor = Colors.grey;

  @override
  void initState() {
    super.initState();

    _audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    if (_audioProvider.currentCover?.isNotEmpty == true) {
      updateBackgroundColor(_audioProvider.currentCover!);
    }

    _audioProvider.addListener(() {
      final cover = _audioProvider.currentCover;
      if (cover != null && cover.isNotEmpty) {
        updateBackgroundColor(cover);
      }
    });
  }

  bool isColorBright(Color color) {
    final brightness =
        (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 180;
  }

  Future<void> updateBackgroundColor(String imageUrl) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
      );
      if (!mounted) return;

      setState(() {
        dominantColor = palette.dominantColor?.color ?? Colors.black;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final player = audioProvider.player;

    if (audioProvider.currentSongPath?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    // xác định màu chữ/icon
    final bool bright = isColorBright(dominantColor);
    final Color textColor = bright ? Colors.black87 : Colors.white;
    final Color subTextColor = bright ? Colors.black54 : Colors.white70;
    final Color iconColor = bright ? Colors.black : Colors.white;

    return AnimatedContainer(
      margin: EdgeInsets.symmetric(horizontal: 6),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            dominantColor.withOpacity(1),
            dominantColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // =============== MINI PLAYER ROW ===============
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    return RotatingImage_1(
                      imagePath: audioProvider.currentCover ?? "",
                      isPlaying: player.playing,
                    );
                  },
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audioProvider.currentTitle ?? "No song",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        audioProvider.currentArtist ?? "",
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

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
                            color: iconColor,
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
                      icon: FaIcon(FontAwesomeIcons.forwardStep,
                          color: iconColor),
                    ),
                  ],
                )
              ],
            ),
          ),

          // ================= PROGRESS BAR =================
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.duration ?? Duration.zero;

              double max = duration.inMilliseconds.toDouble();
              double value = position.inMilliseconds.toDouble();

              if (value > max) value = max;

              double progress = max > 0 ? value / max : 0;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  if (max <= 0) return;
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;

                  final dx = box.globalToLocal(details.globalPosition).dx;
                  final percent = (dx / box.size.width).clamp(0.0, 1.0);
                  player.seek(Duration(milliseconds: (percent * max).toInt()));
                },
                onTapDown: (details) {
                  if (max <= 0) return;
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;

                  final dx = box.globalToLocal(details.globalPosition).dx;
                  final percent = (dx / box.size.width).clamp(0.0, 1.0);
                  player.seek(Duration(milliseconds: (percent * max).toInt()));
                },
                child: Container(
                  height: 3,
                  width: 400,
                  margin: EdgeInsets.only(bottom: 0),
                  decoration: BoxDecoration(
                    color: subTextColor.withOpacity(0.25),   // màu line dưới
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,                      // line chạy
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}
