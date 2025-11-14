import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/search_screen/search_screen.dart';
import 'package:music_app/search_screen/voice_screen.dart';
import 'package:music_app/login_screens/login_demo.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../library_screens/library_screen.dart';
import '../personal_screens/personal_screen.dart';
import '../premium_screen/premium_screen.dart';
import '../provider/audio_player_provider.dart';
import '../provider/models/user_model.dart';
import '../provider/status_provider.dart';
import '../setting_screens/setting_screen.dart';
import '../top_screens/top_chart_screen.dart';
import 'discover_screen.dart';
import 'just_audio_demo.dart';
import 'mini_player.dart';

class MainHome extends StatefulWidget {
  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.loadLastSong(); // load từ SharedPreferences, nếu không có thì currentSongPath=null

    // dùng để load lại status của shuffle và repeat khi mở lại app
    Future.microtask(() {
      final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
      audioProvider.loadLastSettings();
    });
  }

  final List<Color> _backgroundColors = [
    Colors.transparent, // DiscoverScreen
    Color(0xFFD61C4E), // TopChartScreen
    Colors.transparent, // LibraryScreen
    Colors.transparent, // PremiumScreen
  ];

  final List<Text> _screenTitle = [
    Text("Trang chủ", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),),
    Text("Hot", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text("Thư viện", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text("Nâng cấp tài khoản", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
  ];


  Future<void> signOutGoogle(BuildContext context) async {
    try {
      // 1. Đăng xuất Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Đăng xuất Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // 3. Xóa user trong Provider nếu có
      Provider.of<UserProvider>(context, listen: false).clearUser();

      // 4. Chuyển về màn hình login hoặc home
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreenDemo()));

      print("Đăng xuất thành công");
    } catch (e) {
      print("Đăng xuất thất bại: $e");
    }
  }

  Future<void> logout(BuildContext context) async {
    // Đăng xuất Firebase + Google
    await fb.FirebaseAuth.instance.signOut();
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    // Xóa thông tin người dùng và nhạc đã lưu
    context.read<UserProvider>().clearUser();
    await context.read<AudioPlayerProvider>().clearSong();

    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.clearSong();
    // Xóa dữ liệu SharedPreferences của user hiện tại
    final prefs = await SharedPreferences.getInstance();
    final userId = fb.FirebaseAuth.instance.currentUser?.uid ?? "guest";
    await prefs.remove('song_count_$userId');
    await prefs.remove('songId_$userId');
    await prefs.remove('songPath_$userId');
    await prefs.remove('songTitle_$userId');
    await prefs.remove('songArtist_$userId');
    await prefs.remove('songCover_$userId');
    await prefs.remove('isRepeat_$userId');
    await prefs.remove('isShuffle_$userId');
    prefs.clear();

    // Điều hướng về màn hình đăng nhập
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreenDemo()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            return false;
          }
        }
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        key: _scaffoldKey,

        drawer: Drawer(
          width: 350,
          backgroundColor: const Color(0xFF0F0F1C),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              DrawerHeader(
                decoration: const BoxDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // 🔹 căn giữa dọc
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blueAccent.withOpacity(0.15),
                      child:CircleAvatar(
                          radius: 25,
                          //backgroundImage: getUserAvatar(user!),
                          backgroundImage: user?.avatar != null
                              ? NetworkImage(user!.avatar)
                              : AssetImage('assets/images/profile.png') as ImageProvider
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        user?.name ?? 'Khách',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Các menu chính
              _buildDrawerItem(
                icon: Icons.person,
                text: "Hồ sơ cá nhân",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalScreen())),
              ),
              _buildDrawerItem(
                icon: Icons.settings,
                text: "Cài đặt",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
              ),

              const Divider(color: Colors.white24, height: 20, indent: 16, endIndent: 16),

              // Đăng xuất
              _buildDrawerItem(
                icon: Icons.logout,
                text: "Đăng xuất",
                iconColor: Colors.redAccent,
                textColor: Colors.redAccent,
                isBold: true,
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
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
                              const Icon(Icons.logout, size: 50, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              const Text(
                                "Bạn có chắc chắn muốn đăng xuất?",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text("Huỷ"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      logout(context);
                                    },
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
                },
              ),
            ],
          ),
        ),
        // appbar
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(60), // chiều cao AppBar
            child: Consumer<StatusProvider>(
              builder: (_, status, __) {
                return status.showAppBar
                    ? AppBar(
                  backgroundColor: _backgroundColors[_selectedIndex],
                  elevation: 0,
                  title: _screenTitle[_selectedIndex],
                  leading: GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 30,
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 32,
                          backgroundImage: user?.avatar != null
                              ? NetworkImage(user!.avatar)
                              : AssetImage('assets/images/profile.png') as ImageProvider,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.mic_none_rounded, color: Colors.white),
                      onPressed: () {
                        context.read<StatusProvider>().toggleAppBar(false);
                        _navigatorKeys[_selectedIndex].currentState?.push(
                          MaterialPageRoute(builder: (_) => VoiceScreen()),
                        ).then((_) {
                          if (mounted) {
                            context.read<StatusProvider>().toggleAppBar(true);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        context.read<StatusProvider>().toggleAppBar(false);
                        _navigatorKeys[_selectedIndex].currentState?.push(
                          MaterialPageRoute(builder: (_) => SearchScreen()),
                        ).then((_) {
                          if (mounted) {
                            context.read<StatusProvider>().toggleAppBar(true);
                          }
                        });
                      },
                    ),
                  ],
                )
                    : const SizedBox.shrink();
              },
            ),
          ),


        //body
        body: Stack(
          children: [

            Positioned.fill(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildNavigator(0, DiscoverScreen()),
                  _buildNavigator(1, TopChartScreen()),
                  _buildNavigator(2, LibraryScreen()),
                  _buildNavigator(3, PremiumScreen()),
                ],
              ),
            ),

            // MiniPlayer luôn hiển thị ở dưới cùng
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: audioProvider.currentSongPath != null && audioProvider.currentSongPath!.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: const JustAudioDemo(),
                    ),
                  );
                },
                child: MiniPlayer(),
              )
                  : SizedBox.shrink(),
            )
          ],
        ),

        bottomNavigationBar: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black26,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 30,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Trang Chủ', 0),
                _buildNavItem(Icons.local_fire_department_rounded, 'Hot', 1),
                _buildNavItem(Icons.library_music_rounded, 'Thư Viện', 2),
                _buildNavItem(Icons.workspace_premium_rounded, 'Premium', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == _selectedIndex) {
          _navigatorKeys[index]
              .currentState!
              .popUntil((route) => route.isFirst);
        } else {
          setState(() => _selectedIndex = index);
          context.read<StatusProvider>().toggleAppBar(true);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.indigoAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.indigoAccent : Colors.grey.shade400,
              size: isSelected ? 28 : 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.indigoAccent : Colors.grey.shade400,
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider getUserAvatar(UserModel user) {
    if (user.avatarFirstTime != null && user.avatarFirstTime!.isNotEmpty) {
      final file = File(user.avatarFirstTime!);
      if (file.existsSync()) return FileImage(file);
    }

    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return NetworkImage(user.avatar!);
    }

    return AssetImage('assets/images/profile.png');
  }

  // Hàm phụ để tái sử dụng item
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = Colors.white70,
    Color textColor = Colors.white70,
    bool isBold = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      hoverColor: Colors.blueAccent.withOpacity(0.1),
      onTap: onTap,
    );
  }


  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (_) => child);
      },
    );
  }
}