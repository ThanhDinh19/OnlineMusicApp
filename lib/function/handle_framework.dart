import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/provider/models/user_model.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../provider/user_provider.dart';

class HandleFramework {

  HandleFramework();

  Future<UserModel?> checkUserExist(String? email) async {
    try {

      if (email == null || email.isEmpty) {
        print("⚠️ Username null hoặc rỗng — không gửi request");
        return null;
      }

      String url = "http://10.0.2.2:8081/music_API/get_info/get_user_id.php";

      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        var msg = jsonDecode(response.body);

        if (msg['status'] == true) {
          print("Người dùng tồn tại.");
          print(msg['user']);

          UserModel user = UserModel(
              id: msg['user']['id'],
              name: msg['user']['username'],
              email: msg['user']['email'],
              avatar: msg['user']['avatar_url']);

          return user;

        } else {
          // khi khôg thấy user trong database tức là user chưa đăng ký lần nào
          print("Người dùng không tồn tại.");
          return null;
        }
      } else {
        print("Lỗi HTTP: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi: $e");
      return null;
    }
  }

  Future<bool> checkFavoriteArtistsStatus(String? userId) async {
    if (userId == null || userId.isEmpty) return false;

    bool check = false;

    try {
      final url = Uri.parse(
          "http://10.0.2.2:8081/music_API/online_music/artist/check_selected_artist_status.php?user_id=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          check = data["has_favorites"] ?? false;
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi khi kiểm tra nghệ sĩ yêu thích: $e");
    } finally {
      print("Hàm checkFavoriteArtistsStatus() trả về: $check");
    }

    return check;
  }

  Future<bool> checkPremiumStatus() async {
    final ctx = navigatorKey.currentContext;
    final userProvider = Provider.of<UserProvider>(ctx!, listen: false);
    final userId = userProvider.user!.id.toString();
    try {
      final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/ads/check_premium_status.php?user_id=$userId",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == "success") {
          return data["is_premium"];
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi kiểm tra premium: $e");
    }
    return false; // Mặc định là user free nếu có lỗi
  }
}
