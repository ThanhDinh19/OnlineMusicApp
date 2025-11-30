import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/personal_screens/my_playlist_screen.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screens/login_demo.dart';
import '../provider/audio_player_provider.dart';
import '../provider/models/app_strings.dart';
import '../provider/provider_language.dart';
import '../provider_themes/provider_theme.dart';
import '../provider_themes/themes/theme_gird_pro.dart';
import '../setting_screens/setting_screen.dart';

class PersonalScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => PersonalScreenState();
}

class PersonalScreenState extends State<PersonalScreen> {

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

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    context.read<UserProvider>().clearUser();
    await context.read<AudioPlayerProvider>().clearSong();

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreenDemo()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final lang = Provider.of<LanguageProvider>(context).lang;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Avatar + Thông tin
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              backgroundImage: user?.avatar != null
                  ? NetworkImage(user!.avatar)
                  : const AssetImage('assets/images/profile.png'),
            ),
            const SizedBox(height: 14),
            Text(
              S.userName(lang, user!.name) ?? S.userName(lang, "Khách"),
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
             Text(user?.email ?? '',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 20),

            _buildMenuItem(Icons.border_top_rounded, S.theme(lang), (){
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
            }),
            _buildMenuItem(Icons.support_agent, S.notification(lang), () {}),
            _buildMenuItem(Icons.support_agent, S.language(lang), () {
              Provider.of<LanguageProvider>(context, listen: false).toggleLanguage();
            }),
            _buildMenuItem(Icons.support_agent, S.support(lang), () {}),
            _buildMenuItem(Icons.logout, S.logout(lang), () {
              _showLogoutDialog(context);
            }),
          ],
        ),
      ),
    );
  }

  // Thẻ thống kê hoạt động nghe nhạc
  Widget _buildStatCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
       // color: const Color(0xFF44444E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text("Thống kê nghe nhạc tuần này",
              style: TextStyle(
                  color: Colors.indigoAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.65,
            color: Colors.indigoAccent,
            backgroundColor: Colors.grey[800],
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          const Text("Đã nghe 8 giờ",
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
  // Item trong danh sách menu
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
       /// color: const Color(0xFF44444E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigoAccent),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF0F0F1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout,
                    size: 50, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  "Bạn có chắc chắn muốn đăng xuất?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black),
                      child: const Text("Huỷ"),
                    ),
                    ElevatedButton(
                      onPressed: () => logout(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white),
                      child: const Text("Đăng xuất"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
