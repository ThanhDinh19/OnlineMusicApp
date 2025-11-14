import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RotatingImage_1 extends StatefulWidget {
  final String imagePath;
  final bool isPlaying;

  RotatingImage_1({required this.imagePath, required this.isPlaying});

  @override
  _RotatingImageState_1 createState() => _RotatingImageState_1();
}

class _RotatingImageState_1 extends State<RotatingImage_1> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(RotatingImage_1 oldWidget) {
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
        margin: EdgeInsets.all(2),
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(150),
          border: Border.all(width: 5, color: Colors.black45),
          image: DecorationImage(
            image: NetworkImage(widget.imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
