import 'package:flutter/material.dart';

class ThemeGridView extends StatelessWidget {
  final String category;
  const ThemeGridView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, String>>> themesByCategory = {
      "hot": [
        {"name": "Vũ trụ sâu thẳm", "image": "assets/themes/space.jpg", "tag": "HOT"},
        {"name": "Capybara xinh yêu", "image": "assets/themes/capybara.jpg", "tag": "NEW"},
        {"name": "Núi tuyết", "image": "assets/themes/snow.jpg", "tag": ""},
        {"name": "Đại dương xanh", "image": "assets/themes/ocean.jpg", "tag": "NEW"},
        {"name": "Giữa ngân hà", "image": "assets/themes/galaxy.jpg", "tag": "HOT"},
        {"name": "Mặt nước lấp lánh", "image": "assets/themes/water.jpg", "tag": ""},
      ],
      "dark": [
        {"name": "Đêm yên tĩnh", "image": "assets/themes/night.png", "tag": "HOT"},
        {"name": "Neon tím", "image": "assets/themes/neon.jpg", "tag": ""},
      ],
      "cute": [
        {"name": "Chú mèo con", "image": "assets/themes/cat.jpg", "tag": "NEW"},
      ],
      "city": [
        {"name": "Thành phố Tokyo", "image": "assets/themes/tokyo.jpg", "tag": ""},
      ],
      "artist": [
        {"name": "Trừu tượng", "image": "assets/themes/art.jpg", "tag": "HOT"},
      ],
    };

    final themeList = themesByCategory[category] ?? [];

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.5, // điều chỉnh tỉ lệ để ảnh dài hơn
      ),
      itemCount: themeList.length,
      itemBuilder: (context, index) {
        final theme = themeList[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded( // ✅ chỉ cần Expanded ở đây là đủ
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      theme['image']!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (theme['tag']!.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme['tag'] == 'HOT'
                              ? Colors.redAccent
                              : Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          theme['tag']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme['name']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
