import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../provider/audio_player_provider.dart';

class MusicWave extends StatefulWidget {
  const MusicWave({super.key});

  @override
  State<MusicWave> createState() => _MusicWaveState();
}

class _MusicWaveState extends State<MusicWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _controller.repeat(); // bắt đầu animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    final player = audioProvider.player;

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;

        if (playing) {
          _controller.repeat();
        } else {
          _controller.stop();
        }

        return SpinKitWave(
          color: Color(0xFF344CB7),
          size: 30,
          controller: _controller, // điều khiển animation
        );
      },
    );
  }
}
