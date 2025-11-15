import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/helpers/hide_app_bar_observer.dart';
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
    final audioProvider =
    Provider.of<AudioPlayerProvider>(context, listen: false);
    audioProvider.loadLastSong();

    Future.microtask(() {
      audioProvider.loadLastSettings();
    });
  }

  final List<Color> _backgroundColors = [
    Colors.transparent,
    Color(0xFFD61C4E),
    Colors.transparent,
    Colors.transparent,
  ];

  final List<Text> _screenTitle = const [
    Text("Trang chủ",
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text("Hot",
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text("Thư viện",
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text("Nâng cấp tài khoản",
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
  ];

  Future<void> logout(BuildContext context) async {
    await fb.FirebaseAuth.instance.signOut();
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

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final audioProvider = Provider.of<AudioPlayerProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        final isFirstRoute =
        !await _navigatorKeys[_selectedIndex].currentState!.maybePop();

        if (isFirstRoute && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        return isFirstRoute;
      },
      child: Scaffold(
        key: _scaffoldKey,

        // ------------------ DRAWER ------------------
        drawer: Drawer(
          width: 350,
          backgroundColor: const Color(0xFF0F0F1C),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blueAccent.withOpacity(0.15),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: user?.avatar != null
                            ? NetworkImage(user!.avatar)
                            : const AssetImage('assets/images/profile.png'),
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

              _buildDrawerItem(
                icon: Icons.person,
                text: "Hồ sơ cá nhân",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PersonalScreen())),
              ),

              _buildDrawerItem(
                icon: Icons.settings,
                text: "Cài đặt",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen())),
              ),

              const Divider(color: Colors.white24, indent: 16, endIndent: 16),

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
                },
              ),
            ],
          ),
        ),

        // ------------------ APPBAR ------------------
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Consumer<StatusProvider>(
            builder: (_, status, __) {
              return status.getAppBar(_selectedIndex)
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
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        backgroundImage: user?.avatar != null
                            ? NetworkImage(user!.avatar)
                            : const AssetImage('assets/images/profile.png'),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded,
                        color: Colors.white),
                    onPressed: () {
                      _navigatorKeys[_selectedIndex].currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => VoiceScreen(),
                          settings: const RouteSettings(name: "voice"),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      _navigatorKeys[_selectedIndex].currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(),
                          settings: const RouteSettings(name: "search"),
                        ),
                      );
                    },
                  )
                ],
              )
                  : const SizedBox.shrink();
            },
          ),
        ),

        // ------------------ BODY ------------------
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

            // MINI PLAYER
            if (audioProvider.currentSongPath != null &&
                audioProvider.currentSongPath!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
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
                ),
              ),
          ],
        ),

        // ------------------ BOTTOM NAV ------------------
        bottomNavigationBar: Container(
          height: 70,
          decoration: const BoxDecoration(
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
                _navItem(Icons.home_rounded, 'Trang Chủ', 0),
                _navItem(Icons.local_fire_department_rounded, 'Hot', 1),
                _navItem(Icons.library_music_rounded, 'Thư Viện', 2),
                _navItem(Icons.workspace_premium_rounded, 'Premium', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ NAV ITEM ------------------
  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == _selectedIndex) {
          _navigatorKeys[index]
              .currentState!
              .popUntil((route) => route.isFirst);
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.indigoAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? Colors.indigoAccent
                    : Colors.grey.shade400,
                size: isSelected ? 28 : 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.indigoAccent
                      : Colors.grey.shade400,
                  fontSize: isSelected ? 12 : 11,
                )),
          ],
        ),
      ),
    );
  }

  // ------------------ NAVIGATION (MULTI NAVIGATOR) ------------------
  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: [
        HideAppBarObserver(index, (tab, show) {
          context.read<StatusProvider>().setAppBar(tab, show);
        }),
      ],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => child,
          settings: settings,
        );
      },
    );
  }

  // Drawer Item UI
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
      onTap: onTap,
    );
  }
}
