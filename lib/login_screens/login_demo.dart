import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_app/artist_select/artist_select_screen.dart';
import 'package:music_app/provider/audio_player_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screens/main_home.dart';
import '../provider/models/user_model.dart';
import '../provider/user_provider.dart';
import 'dart:io';
class LoginScreenDemo extends StatefulWidget {
  const LoginScreenDemo({super.key});
  @override
  LoginScreenDemoState createState() => LoginScreenDemoState();
}

class LoginScreenDemoState extends State<LoginScreenDemo> {
  String? phoneError; // hiển thị lỗi
  String? passwordError; // hiển thị lỗi

  final phoneController = TextEditingController();
  final pwdController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    pwdController.dispose();
    super.dispose();
  }

  Future<File> downloadAvatar(String url, String fileName) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/avatars';
    await Directory(path).create(recursive: true); // tạo thư mục nếu chưa có

    File file = File('$path/$fileName');

    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to download avatar: ${response.statusCode}');
    }
  }

  Future userLoginWithGoogle(fb.User usergg) async {
    bool loginSuccess = false;
    bool isNewUser = false; // Thêm biến đánh dấu đăng ký mới

    try {
      String url = "http://10.0.2.2:8081/music_API/login_api/user_login_google.php";
      print("🔗 POST to $url");

      var data = {
        'username': usergg.displayName,
        'password': '#',
        'email': usergg.email,
        'avatar': usergg.photoURL,
      };

      var response = await http.post(Uri.parse(url), body: json.encode(data));

      print("Response code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var msg = jsonDecode(response.body);

        if (msg['loginStatus'] == true) {
          // Check nếu là người dùng mới (đăng ký lần đầu)
          if (msg['message'].toString().contains('Đăng ký thành công')) {
            isNewUser = true;
          }

          String path = msg['userInfo']['avatar_url'];
          List<String> paths = path.split('/');

          final file = await downloadAvatar(usergg.photoURL.toString(), paths[2]);

          final user = UserModel(
            id: msg['userInfo']['id'].toString(),
            name: msg['userInfo']['username'].toString(),
            email: msg['userInfo']['email'].toString(),
            avatar: msg['userInfo']['avatar_url'].toString(),
            avatarFirstTime: file.path,
          );

          Provider.of<UserProvider>(context, listen: false).setUser(user);
          loginSuccess = true;

          final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
          await audioProvider.checkAndUpdatePremium();
        }
      } else {
        showMessage("Error during connecting to Server.");
      }
    } catch (e) {
      print("Đăng nhập thất bại: $e");
    }

    // Chỉ chuyển màn hình 1 lần dựa theo trạng thái
    if (loginSuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (isNewUser) {
        // Nếu là người mới → qua chọn nghệ sĩ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ArtistSelectScreen()),
        );
      } else {
        // Nếu user cũ → vào MainHome luôn
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainHome()),
        );
      }
    }
  }



  Future<void> showMessage(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false, // không cho người dùng đóng bằng chạm ngoài
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon thông báo
                Icon(Icons.info_outline, size: 50, color: Colors.indigoAccent),
                SizedBox(height: 16),
                // Nội dung thông báo
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                // Nút OK
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "OK",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          Container(
            height: 300,
          ),
          Icon(
            Icons.music_note,
            color: Colors.indigoAccent,
            size: 65,
          ),

          SizedBox(height: 15),

          Center(
            child: Text(
              'Chào mừng đến với Chill Chill.\n'
              'Âm nhạc đang chờ bạn khám phá.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold, ),
            ),
          ),


          SizedBox(height: 270),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              minimumSize: Size(370, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(5),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            icon: Image.asset("assets/images/profile.png", height: 30, width: 30),
            label: Text("Khách", style: TextStyle(color: Colors.white70, fontSize: 15),),


            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainHome()),
              );
            }

          ),

          SizedBox(height: 10),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              minimumSize: Size(370, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(5),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            icon: Image.asset("assets/images/icon_gg.png", height: 24, width: 24),
            label: Text("Đăng nhập với google",  style: TextStyle(color: Colors.white70, fontSize: 15),),


            onPressed: () async {
              try {
                final GoogleSignIn googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();

                final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
                if (googleUser == null) return;

                final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

                final credential = fb.GoogleAuthProvider.credential(
                  accessToken: googleAuth.accessToken,
                  idToken: googleAuth.idToken,
                );

                final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
                final usergg = userCredential.user;

                if (usergg != null) {
                  await userLoginWithGoogle(usergg); // tiến trình login + tải avatar
                }
              } catch (e) {
                print("Đăng nhập thất bại: $e");
              }
            },

          ),
        ],
      )
    );
  }
}