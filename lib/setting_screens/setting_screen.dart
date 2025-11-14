
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider_themes/provider_theme.dart';
import '../provider_themes/themes/theme_gird_pro.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin{
  bool isDarkMode = false;
  bool isNotificationOn = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  // loại theme thông thường
  final List<Map<String, dynamic>> themes = [
    {'name': 'Mặc định', 'color': Color(0xFF0F0F1C), 'textColor': Colors.white},
    {'name': 'Summer', 'color': Color(0xFFFFB433), 'textColor': Colors.black},
    {'name': 'Fall', 'color': Color(0xFFD6D46D), 'textColor': Colors.black},
    {'name': 'Winter', 'color': Colors.blueAccent, 'textColor': Colors.black},
    {'name': 'Spring', 'color': Colors.greenAccent, 'textColor': Colors.black},
    {'name': 'Warm', 'color': Color(0xFF3E0703), 'textColor': Colors.white},
    {'name': 'Cold', 'color': Color(0xFF9B5DE0), 'textColor': Colors.white},
    {'name': 'Happy', 'color': Color(0xFFDD7BDF), 'textColor': Colors.white},
    {'name': 'Nature', 'color': Color(0xFF8FA31E), 'textColor': Colors.white},
  ];

  final List<Map<String, dynamic>> themesPro = [
    {'name': 'Phi hành gia', 'themeImage': 'assets/themes/phi_hanh_gia.jpg'}
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin người dùng
          Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/images/profile.png'),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Thanh Dinh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("thanh@example.com"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Giao diện
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("Chủ đề"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                builder: (_) {
                  return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.9,   // lúc đầu chiếm 60% màn hình
                      minChildSize: 0.1,       // thấp nhất 40%
                      maxChildSize: 0.95,      // kéo hết cỡ tới 95%
                      builder: (context, scrollController){
                        return DefaultTabController(
                          length: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [


                                // ============== chủ đề free ================
                                const Text(
                                  'Chủ đề mới',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    itemCount: themes.length,
                                    itemBuilder: (context, index) {
                                      final theme = themes[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                themeProvider.setCustomColor(
                                                  theme['color'],
                                                  theme['textColor'],
                                                );
                                              },
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: theme['color'],
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: theme['color'].withOpacity(0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(Icons.palette, color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              theme['name'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // ============== chủ đề pro ================
                                const SizedBox(height: 20),
                                TabBar(
                                  isScrollable: true,
                                  indicatorColor: Colors.blueAccent,
                                  labelColor: Colors.blueAccent,
                                  unselectedLabelColor: Colors.white70,
                                  tabs: [
                                    Tab(text: "🔥 Hot"),
                                    Tab(text: "🌙 Nền tối"),
                                    Tab(text: "🐻 Dễ thương"),
                                    Tab(text: "🏙 Thành phố"),
                                    Tab(text: "🎨 Nghệ sĩ"),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      ThemeGridView(category: "hot"),
                                      ThemeGridView(category: "dark"),
                                      ThemeGridView(category: "cute"),
                                      ThemeGridView(category: "city"),
                                      ThemeGridView(category: "artist"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                  );
                },
              );

            },
          ),
          SwitchListTile(
            activeColor: Colors.lightGreen,
            title: const Text("Thông báo"),
            secondary: const Icon(Icons.notifications),
            value: isNotificationOn,
            onChanged: (value) {
              setState(() => isNotificationOn = value);
            },
          ),

          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("Chất lượng nhạc"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showQualityDialog(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Ngôn ngữ"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chọn chất lượng nhạc"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(title: Text("Thấp")),
            ListTile(title: Text("Trung bình")),
            ListTile(title: Text("Cao")),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chọn ngôn ngữ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(title: Text("Tiếng Việt")),
            ListTile(title: Text("English")),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold),),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(onPressed: () {}, child: const Text("Đăng xuất"  ,style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }



}
