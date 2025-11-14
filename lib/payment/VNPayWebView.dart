import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VNPayWebView extends StatefulWidget {
  final String url;

  const VNPayWebView({super.key, required this.url});

  @override
  State<VNPayWebView> createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            print("Loaded: $url");
          },
          onNavigationRequest: (request) {
            // Khi VNPay redirect về Return URL
            if (request.url.contains("check-payment-vnpay")) {
              Navigator.pop(context);
              _showResult(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _showResult(String url) {
    if (url.contains("vnp_ResponseCode=00")) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Thanh toán thành công"),
          content: Text("Bạn đã nâng cấp Premium!"),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Thanh toán thất bại"),
          content: Text("Vui lòng thử lại!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thanh toán VNPay")),
      body: WebViewWidget(controller: controller),
    );
  }
}
