import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:music_app/function/handle_framework.dart';
import 'package:music_app/login_screens/login_demo.dart';
import 'package:music_app/provider/audio_player_provider.dart';
import 'package:music_app/provider/favorite_album_provider.dart';
import 'package:music_app/provider/favorite_song_provider.dart';
import 'package:music_app/provider/models/user_model.dart';
import 'package:music_app/provider/status_provider.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/provider_themes/provider_theme.dart';
import 'package:provider/provider.dart';
import 'artist_select/artist_select_screen.dart';
import 'firebase_options.dart';
import 'home_screens/main_home.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final userProvider = UserProvider();
  final fb.User? firebaseUser = fb.FirebaseAuth.instance.currentUser;
  bool isLoggedIn = false;
  bool checkArtistSelectStatus = false;

  HandleFramework d = HandleFramework();
  UserModel? user;

  // Kiểm tra xem user firebase có tồn tại trong database không
  if (firebaseUser != null && firebaseUser.email != null) {
    user = await d.checkUserExist(firebaseUser.email);
  }

  // Nếu user tồn tại trong database
  if (user != null) {
    userProvider.setUser(user);
    isLoggedIn = true;

    // Kiểm tra xem user này đã chọn nghệ sĩ yêu thích chưa
    checkArtistSelectStatus = await d.checkFavoriteArtistsStatus(user.id.toString());
    print("user: ${user.id.toString()}");
  }

  // Nếu user chưa login, giữ nguyên giá trị false
  print("isLoggedIn = $isLoggedIn | checkArtistSelectStatus = $checkArtistSelectStatus");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider(create: (context) => AudioPlayerProvider(context)),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteAlbumProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteSongProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn, isSelected: checkArtistSelectStatus),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isSelected;
  const MyApp({required this.isLoggedIn, required this.isSelected, super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: themeProvider.theme,
          home: _getInitialScreen(context),
        );
      },
    );
  }

  Widget _getInitialScreen(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if(user == null){
      return LoginScreenDemo();
    }
    if (isLoggedIn == true && isSelected == true) {
      return MainHome();
    }
    return const ArtistSelectScreen();
  }
}
