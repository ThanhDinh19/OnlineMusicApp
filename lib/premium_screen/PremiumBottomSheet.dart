import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../payment/VNPayWebView.dart';
import '../payment/VNPayWebViewBottomSheet.dart';
import '../provider/user_provider.dart';

class PremiumBottomSheet extends StatefulWidget {
  const PremiumBottomSheet({super.key});

  @override
  State<PremiumBottomSheet> createState() => _PremiumBottomSheetState();
}

class _PremiumBottomSheetState extends State<PremiumBottomSheet> {
  int selected = 0;
  List<Map<String, dynamic>> plans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPlans();
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
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.65,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F1C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _buildContent(scrollController),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scroll) {
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.all(16),
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
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 16),

        const Text(
          "* Nghe nhạc không quảng cáo\n"
              "* Tải nhạc nghe offline\n"
              "* Không giới hạn bài hát",
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
        ),

        const SizedBox(height: 28),

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
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18)),
                  Text("${plan["price"]}đ",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 17)),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () async {
            final selectedPlan = plans[selected];
            final user =
                Provider.of<UserProvider>(context, listen: false).user;

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

            if (res.statusCode == 201) {
              final paymentUrl = data["paymentUrl"];

              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => VNPayWebViewBottomSheet(
                  url: paymentUrl,
                  planId: selectedPlan["id"].toString(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text(
            "Nâng cấp ngay",
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),

        const SizedBox(height: 20),
        const Center(
          child: Text(
            "Thanh toán qua VNPay.",
            style: TextStyle(color: Colors.white54),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}
