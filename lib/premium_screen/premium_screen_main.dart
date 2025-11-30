import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:music_app/provider/premium_povider.dart';
import 'package:provider/provider.dart';
import '../payment/VNPayWebView.dart';
import '../provider/user_provider.dart';

class PremiumScreenMain extends StatefulWidget {
  const PremiumScreenMain({super.key});

  @override
  State<PremiumScreenMain> createState() => _PremiumScreenMainState();
}

class _PremiumScreenMainState extends State<PremiumScreenMain> {
  int selected = 0;

  List<Map<String, dynamic>> plans = [];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PremiumProvider>(context, listen: false).checkPremiumStatus(user!.id.toString());
    });
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    final url = Uri.parse("http://10.0.2.2:8081/music_API/online_music/ads/get_subscription_plans.php");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        setState(() {
          plans = List<Map<String, dynamic>>.from(data["plans"]);

        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context);
    String endDay = premiumProvider!.endDay;
    String dayLeft = premiumProvider!.dayLeft;
    return Scaffold(
      appBar: AppBar(
        title: Text("Nâng cấp tài khoản", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: (){
            Navigator.pop(context);
          },
        ),
      ),
      body: plans.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if(endDay.isNotEmpty && dayLeft.isNotEmpty)...[
                Center(child: Text("Tài khoản premium"),),
                Center(child: Text("Ngày hết hạn: ${endDay}"),),
                Center(child: Text("Còn lại: ${dayLeft}"),),
              ],
              const SizedBox(height: 16),
              const Text("Trải nghiệm âm nhạc không giới hạn!",
                  style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 16),

              const Text(
                "* Nghe nhạc không quảng cáo\n"
                    "* Tải nhạc nghe offline\n"
                    "* Không giới hạn bài hát",
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 30),

              const Text("Chọn gói Premium của bạn",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 12),

              ...List.generate(plans.length, (index) {
                final plan = plans[index];
                final isSelected = index == selected;
                final formattedPrice = NumberFormat("#,###", "vi_VN").format(plan["price"]);
                return GestureDetector(
                  onTap: () => setState(() => selected = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurpleAccent.withOpacity(0.3)
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.amberAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(plan["name"],
                            style: const TextStyle(color: Colors.white, fontSize: 15)),

                        Text("${formattedPrice} VND",
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: () async {

                    if(endDay.isNotEmpty && dayLeft.isNotEmpty){
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Tài khoản premium của bạn vẫn còn hiệu lực", textAlign: TextAlign.center,),
                        ),
                      );
                      return;
                    }

                    final selectedPlan = plans[selected];
                    final user = Provider.of<UserProvider>(context, listen: false).user;
                    // gọi API tạo payment url
                    final res = await http.post(
                      Uri.parse("http://10.0.2.2:3000/api/create-qr"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "user_id": user!.id.toString(),
                        "plan_id": selectedPlan["id"],
                      }),
                    );

                    final data = jsonDecode(res.body);
                    final durationDays = data["duration_days"];

                    if (res.statusCode == 201) {
                      final paymentUrl = data["paymentUrl"];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VNPayWebView(
                            url: paymentUrl,
                            planId: selectedPlan["id"].toString(),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 130),
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "Nâng cấp ngay",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Thanh toán qua VNPay.",
                  style: TextStyle(color: Colors.white54),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
