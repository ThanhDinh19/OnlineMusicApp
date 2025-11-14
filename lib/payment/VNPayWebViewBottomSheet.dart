import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class VNPayWebViewBottomSheet extends StatefulWidget {
  final String url;
  final String planId;

  const VNPayWebViewBottomSheet({
    super.key,
    required this.url,
    required this.planId,
  });

  @override
  State<VNPayWebViewBottomSheet> createState() => _VNPayWebViewBottomSheetState();
}

class _VNPayWebViewBottomSheetState extends State<VNPayWebViewBottomSheet> {
  late WebViewController controller;
  bool handled = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _handleCallback(url),
          onNavigationRequest: (req) {
            _handleCallback(req.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _handleCallback(String url) async {
    if (handled) return;

    if (!url.contains("vnp_TxnRef") || !url.contains("vnp_ResponseCode")) {
      return;
    }

    handled = true;

    final uri = Uri.parse(url);
    final txnRef = uri.queryParameters["vnp_TxnRef"];
    final resp = uri.queryParameters["vnp_ResponseCode"];
    final user = Provider.of<UserProvider>(context, listen: false).user;

    if (resp == "00") {
      // Gửi xác nhận thanh toán
      await http.post(
        Uri.parse("http://10.0.2.2:3000/api/confirm-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "txn_ref": txnRef,
          "user_id": user!.id.toString(),
          "plan_id": widget.planId,
        }),
      );

      if (!mounted) return;

      Navigator.pop(context); // đóng bottom sheet

      // Show dialog sau khi đóng
      Future.delayed(const Duration(milliseconds: 150), () {
        showDialog(
          context: context,
          builder: (_) =>
          const AlertDialog(title: Text("Thanh toán thành công!")),
        );
      });
    } else {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controllerScroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Drag handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 10),

              // App bar title
              const Text(
                "VNPay Checkout",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // WebView chiếm full phần còn lại
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: WebViewWidget(
                    controller: controller,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}
