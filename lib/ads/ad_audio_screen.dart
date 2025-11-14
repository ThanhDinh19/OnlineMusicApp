import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../audio/music_wave.dart';
import '../handle_image/rotating_image.dart';
import '../provider/audio_player_provider.dart';
import 'package:just_audio/just_audio.dart';

class AdAudioScreen extends StatefulWidget {
  const AdAudioScreen({super.key});

  @override
  State<AdAudioScreen> createState() => _AdAudioScreenState();
}

class _AdAudioScreenState extends State<AdAudioScreen> {
  @override
  void initState() {
    super.initState();
    final player = Provider.of<AudioPlayerProvider>(context, listen: false).player;

    // Lắng nghe khi phát xong quảng cáo
    player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed && mounted) {
        // Tự đóng màn quảng cáo nếu vẫn còn mở
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final player = audioProvider.adPlayer;
    final ad = audioProvider.currentAd;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF37353E),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Ảnh quảng cáo
              RotatingImage(
                imagePath: ad?["cover_url"] ?? "",
                isPlaying: true,
              ),
              const SizedBox(height: 40),

              // Tiêu đề quảng cáo
              Text(
                ad?["title"] ?? "Quảng cáo",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Từ thương hiệu: ${ad?["brand_name"] ?? "ChillChill"}",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),

              const Text(
                "Đang phát quảng cáo",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 50),

              // Thanh tiến trình phát quảng cáo
              // Thanh tiến trình phát quảng cáo
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = player.duration ?? Duration.zero;

                  final posSeconds = position.inSeconds.toDouble();
                  final maxSeconds = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;

                  return Column(
                    children: [
                      Slider(
                        value: posSeconds.clamp(0, maxSeconds),
                        max: maxSeconds,
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                        onChanged: (_) {}, // không cho tua
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // Nút đóng (disabled)
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.circleXmark,
                    color: Colors.white, size: 35),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Hãy nghe hết quảng cáo nhé"),
                    duration: Duration(seconds: 2),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
