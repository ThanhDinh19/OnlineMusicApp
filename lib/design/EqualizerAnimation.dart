import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EqualizerAnimation extends StatefulWidget {
  final bool isPlaying; // thêm biến điều khiển
  const EqualizerAnimation({Key? key, required this.isPlaying}) : super(key: key);

  @override
  State<EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<EqualizerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EqualizerAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bar(value * 25),
              _bar((1 - value) * 25),
              _bar((value * 25) / 2),
            ],
          );
        },
      ),
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFFFFE700),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
