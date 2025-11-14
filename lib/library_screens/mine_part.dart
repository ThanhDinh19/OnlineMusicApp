import 'package:flutter/material.dart';

class MinePart extends StatelessWidget {
  const MinePart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 👉 Phần kéo ngang
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              MinePartCard(
                title: 'Favorite',
                color1: Colors.white10,
                color2: Colors.white12,
                icon: Icons.favorite_border,
                iconColor: Colors.blueAccent,
                onPressed:  (){
                  print("");
                },
              ),
              SizedBox(width: 12),
              MinePartCard(
                title: 'downloaded',
                color1: Colors.white10,
                color2: Colors.white12,
                icon: Icons.download_for_offline_outlined,
                iconColor: Colors.lightGreen,
                onPressed:  (){
                  print("");
                },
              ),
              SizedBox(width: 12),
              MinePartCard(
                title: 'Artist',
                color1: Colors.white10,
                color2: Colors.white12,
                icon: Icons.spatial_tracking_outlined,
                iconColor: Colors.orange,
                onPressed:  (){
                  print("");
                },
              ),
              SizedBox(width: 12),
              MinePartCard(
                title: 'MV',
                color1: Colors.white10,
                color2: Colors.white12,
                icon: Icons.music_video,
                iconColor: Colors.redAccent,
                onPressed:  (){
                  print("");
                },
              ),
            ],
          ),
        ),
      ],
    );
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
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
    );
  }
}
