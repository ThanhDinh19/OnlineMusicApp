import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:music_app/design/icon_above_text_button.dart';
import 'package:flutter/material.dart';


class BottomButton extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomButton({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {"icon": FontAwesomeIcons.music, "label": "Library"},
      {"icon": FontAwesomeIcons.explosion, "label": "Discover"},
      {"icon": FontAwesomeIcons.chartLine, "label": "Top"},
      {"icon": FontAwesomeIcons.person, "label": "Personal"},
    ];

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex;
          return IconAboveTextButton(
            icon: items[index]['icon'] as IconData,
            label: items[index]['label'] as String,
            color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
            onPressed: () => onItemTapped(index),
          );
        }),
      ),
    );
  }
}



class IconAboveTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const IconAboveTextButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
