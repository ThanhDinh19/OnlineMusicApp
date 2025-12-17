import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:music_app/provider/premium_povider.dart';
import 'package:provider/provider.dart';
import '../payment/MoMoWebView.dart';
import '../payment/VNPayWebView.dart';
import '../provider/user_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
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

  Future<String?> createMoMoPayment(String planId, String userId) async {
    final url = Uri.parse("http://10.0.2.2:3000/api/momo");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "plan_id": planId,
      }),
    );

    final data = jsonDecode(res.body);
    return data["payUrl"];
  }
  void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black.withOpacity(0.7),
      textColor: Colors.white,
      fontSize: 16,
    );

    // Tuỳ chọn: tự tắt sớm hơn (nếu muốn)
    Future.delayed(const Duration(seconds: 1), () {
      Fluttertoast.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final premiumProvider = Provider.of<PremiumProvider>(context);
    String endDay = premiumProvider!.endDay;
    String dayLeft = premiumProvider!.dayLeft;
    return Scaffold(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 120),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "Nâng cấp ngay",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  onPressed: () async {

                    if(user == null){
                      showToast("Hãy đăng nhập tài khoản ngay,\n để trải nghiệm Premium");
                      return;
                    }
                    if(endDay.isNotEmpty && dayLeft.isNotEmpty) {
                      showToast("Gói Premium của bạn vẫn còn hạn \nđến ngày ${endDay.toString()}");
                      return;
                    }
                    // Hiện bottom sheet với 2 lựa chọn thanh toán
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.9,
                          minChildSize: 0.2,
                          maxChildSize: 0.9,
                          expand: false,
                          builder: (context, scrollController) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E201E),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              ),
                              child: ListView(
                                controller: scrollController,
                                children: [
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Container(
                                      width: 48,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Chọn phương thức thanh toán",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 14),

                                  // VNPay option
                                  ListTile(
                                    leading: Image.asset("assets/images/vnpay_logo.png", width: 36, height: 36, fit: BoxFit.contain), // nếu không có icon, thay bằng Icon(...)
                                    title: const Text("Thanh toán qua VNPAY", style: TextStyle(color: Colors.white)),
                                    subtitle: const Text("Thanh toán bằng VNPAY QR hoặc cổng VNPAY", style: TextStyle(color: Colors.white54)),
                                    onTap: () async {

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
                                        Uri.parse("http://10.0.2.2:3001/api/create-qr"),
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
                                  ),

                                  const Divider(color: Colors.white24),

                                  // MoMo option
                                  ListTile(
                                    leading: Image.asset("assets/images/momo_logo.png", width: 36, height: 36, fit: BoxFit.contain),
                                    title: const Text("Thanh toán qua MoMo", style: TextStyle(color: Colors.white)),
                                    subtitle: const Text("Thanh toán bằng ví MoMo", style: TextStyle(color: Colors.white54)),
                                    onTap: () async {
                                      final selectedPlan = plans[selected];
                                      final user = Provider.of<UserProvider>(context, listen: false).user;

                                      final payUrl = await createMoMoPayment(
                                        selectedPlan["id"].toString(),
                                        user!.id.toString(),
                                      );

                                      if (payUrl != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MoMoWebView(
                                              url: payUrl,
                                              planId: selectedPlan["id"].toString(),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  ),

                                  const SizedBox(height: 12),

                                  // Hủy
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text("Huỷ", style: TextStyle(color: Colors.white70)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Thanh toán qua MoMo.",
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
