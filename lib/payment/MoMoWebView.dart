import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../provider/premium_povider.dart';
import '../provider/user_provider.dart';

class MoMoWebView extends StatefulWidget {
  final String url;
  final String planId;

  const MoMoWebView({
    super.key,
    required this.url,
    required this.planId,
  });

  @override
  State<MoMoWebView> createState() => _MoMoWebViewState();
}

class _MoMoWebViewState extends State<MoMoWebView> {
  late WebViewController controller;
  bool handled = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final url = request.url;
            print("NAVIGATE: $url");

            // mở MoMo app
            if (url.startsWith("momo://")) {
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }

            // bắt callback từ server
            if (url.contains("momo-result") && !handled) {
              handled = true;

              final uri = Uri.parse(url);
              final orderId = uri.queryParameters["orderId"];
              final resultCode = uri.queryParameters["resultCode"];

              if (resultCode == "0") {
                await _confirmPayment(orderId!);
              } else {
                Navigator.pop(context);
              }

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _confirmPayment(String orderId) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    final res = await http.post(
      Uri.parse("http://10.0.2.2:3000/api/confirm-momo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "orderId": orderId,
        "user_id": user!.id.toString(),
        "plan_id": widget.planId,
      }),
    );

    final data = jsonDecode(res.body);
    final days = data["duration_days"];

    if (!mounted) return;

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thanh toán thành công"),
        content: Text("Premium của bạn có hiệu lực: $days ngày"),
      ),
    );

    Provider.of<PremiumProvider>(context, listen: false)
        .checkPremiumStatus(user.id.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán MoMo")),
      body: WebViewWidget(controller: controller),
    );
  }
}
