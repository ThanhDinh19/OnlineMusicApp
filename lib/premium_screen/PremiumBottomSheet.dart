import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../payment/MomoPaymentBottomSheet.dart';
import '../payment/momo_payment_screen.dart';
import '../provider/user_provider.dart';

class PremiumBottomSheet extends StatefulWidget {
  const PremiumBottomSheet({super.key});

  @override
  State<PremiumBottomSheet> createState() => _PremiumBottomSheetState();
}

class _PremiumBottomSheetState extends State<PremiumBottomSheet> {
  int selected = 0;
  List<Map<String, dynamic>> plans = [];

  @override
  void initState() {
    fetchPlans();
    super.initState();
  }

  Future<void> fetchPlans() async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/ads/get_subscription_plans.php");

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
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F1C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text(
                "Trải nghiệm âm nhạc không giới hạn!",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 16),

              const Text(
                "* Nghe nhạc không quảng cáo\n"
                    "* Tải nhạc nghe offline\n"
                    "* Không giới hạn bài hát",
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
              ),

              const SizedBox(height: 30),

              const Text(
                "Chọn gói Premium của bạn",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),

              ...List.generate(plans.length, (index) {
                final plan = plans[index];
                final isSelected = index == selected;

                return GestureDetector(
                  onTap: () => setState(() => selected = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurpleAccent.withOpacity(0.25)
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
                            style: const TextStyle(color: Colors.white, fontSize: 18)),
                        Text("${plan["price"]}đ",
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (plans.isEmpty) return;

                  final user = Provider.of<UserProvider>(context, listen: false).user!;
                  final plan = plans[selected];

                  final result = await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => MomoPaymentBottomSheet(
                      planName: plan["name"],
                      amount: double.parse(plan["price"]),
                    ),
                  );


                  if (result != true) return;

                  final res = await http.post(
                    Uri.parse(
                        "http://10.0.2.2:8081/music_API/online_music/ads/subscribe_user.php"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "user_id": user.id,
                      "plan_id": plan["id"],
                    }),
                  );

                  final data = jsonDecode(res.body);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${data["message"]}")),
                  );

                  if (data["status"] == "success") {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      Navigator.pop(context); // Đóng bottom sheet
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  "Nâng cấp ngay",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  "Thanh toán qua MoMo. Hủy bất kỳ lúc nào.",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
