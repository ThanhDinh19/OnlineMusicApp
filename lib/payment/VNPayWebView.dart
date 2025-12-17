import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

import '../provider/premium_povider.dart';

class VNPayWebView extends StatefulWidget {
  final String url;
  final String planId;

  const VNPayWebView({super.key, required this.url, required this.planId});

  @override
  State<VNPayWebView> createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late WebViewController controller;
  bool handled = false; // tránh gọi confirm nhiều lần

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _handleCallback, // dùng page finished
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _handleCallback(String url) async {
    if (handled) return;

    // CHỈ xử lý khi có đủ 2 params
    if (!url.contains("vnp_TxnRef") || !url.contains("vnp_ResponseCode")) {
      return;
    }
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    final uri = Uri.parse(url);
    final resp = uri.queryParameters["vnp_ResponseCode"];
    final txnRef = uri.queryParameters["vnp_TxnRef"];

    if (resp == "00") {
      handled = true;

      // Gửi JSON đúng cách
      final res =  await http.post(
        Uri.parse("http://10.0.2.2:3001/api/confirm-payment"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "txn_ref": txnRef!,
          "user_id": userProvider!.id.toString(),
          "plan_id": widget.planId,
        }),
      );

      final data = jsonDecode(res.body);
      final durationDays = data["duration_days"];

      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Thanh toán thành công!", textAlign: TextAlign.center,),
            content: Text("Gói Premium của bạn có hiệu lực: $durationDays ngày.",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        );
        final user = Provider.of<UserProvider>(context, listen: false).user;
        final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
        premiumProvider.checkPremiumStatus(user!.id.toString());
      }
    } else {
      if (!handled) {
        handled = true;
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Thanh toán VNPay"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}