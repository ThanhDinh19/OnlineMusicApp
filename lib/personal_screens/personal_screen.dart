import 'package:flutter/material.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../setting_screens/setting_screen.dart';

class PersonalScreen extends StatelessWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;


    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🧑 Avatar + Thông tin
            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage("assets/images/profile.png"),
            ),
            const SizedBox(height: 14),
            Text(
              user?.name ?? 'Khách',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
             Text(user?.email ?? '',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 20),

            // 🎶 Nghe gần đây
            _buildStatCard(),

            const SizedBox(height: 28),
            // ⚙️ Menu
            _buildMenuItem(Icons.playlist_play, "Danh sách phát của tôi", () {}),
            _buildMenuItem(Icons.access_time, "Đã nghe gần đây", () {}),
            _buildMenuItem(Icons.settings, "Cài đặt", () {
              Navigator.push(context,MaterialPageRoute(builder: (context)=> SettingsScreen()));
            }),
            _buildMenuItem(Icons.support_agent, "Trợ giúp & Hỗ trợ", () {}),
            _buildMenuItem(Icons.logout, "Đăng xuất", () {
              // TODO: Logout logic here
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã đăng xuất!'),
              ));
            }),
          ],
        ),
      ),
    );
  }

  // 📊 Thẻ thống kê hoạt động nghe nhạc
  Widget _buildStatCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
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
          const Text("🎧 Đã nghe 8 giờ",
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // 📋 Item trong danh sách menu
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
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
}
