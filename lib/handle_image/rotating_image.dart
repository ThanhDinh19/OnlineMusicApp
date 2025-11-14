import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RotatingImage extends StatefulWidget {
  final String imagePath;
  final bool isPlaying;

  RotatingImage({required this.imagePath, required this.isPlaying});

  @override
  _RotatingImageState createState() => _RotatingImageState();
}

class _RotatingImageState extends State<RotatingImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // quay hết 1 vòng trong 20s
      vsync: this,
    )..repeat(); // chạy xoay vô hạn
    _controller.stop(); // ban đầu dừng
  }

  @override
  void didUpdateWidget(RotatingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.forward();
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 320,
        width: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 20,
              offset: const Offset(0, 10), // bóng dưới nhẹ
            ),
          ],
          gradient: const RadialGradient(
            colors: [
              Color(0xFF202020),
              Color(0xFF101010),
            ],
            center: Alignment(-0.3, -0.3),
            radius: 1.0,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.1), // viền sáng nhẹ
              width: 4,
            ),
            image: DecorationImage(
              image: NetworkImage(widget.imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );

  }
}
