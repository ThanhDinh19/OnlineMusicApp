import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class PremiumProvider extends ChangeNotifier{
  bool isPremium = false;
  String endDay = "";
  String dayLeft = "";


  Future<void> checkPremiumStatus(String userId) async {
    try {
      final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/ads/check_premium_status.php?user_id=$userId",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == "success") {
          if(data["is_premium"] == true){
            isPremium = true;
            endDay = data["end_date"].toString();
            dayLeft = data["days_left"].toString();
          }
          else {
            isPremium = false;
            endDay = "";
            dayLeft = "";
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi kiểm tra premium: $e");
    }
    notifyListeners();
  }
}