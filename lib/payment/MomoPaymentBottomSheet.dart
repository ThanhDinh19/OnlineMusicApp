import 'dart:async';
import 'package:flutter/material.dart';

class MomoPaymentBottomSheet extends StatefulWidget {
  final String planName;
  final double amount;

  const MomoPaymentBottomSheet({
    super.key,
    required this.planName,
    required this.amount,
  });

  @override
  State<MomoPaymentBottomSheet> createState() => _MomoPaymentBottomSheetState();
}

class _MomoPaymentBottomSheetState extends State<MomoPaymentBottomSheet> {
  int countdown = 60;
  Timer? timer;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown == 0) {
        t.cancel();
        Navigator.pop(context, false);
      } else {
        setState(() => countdown--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void simulatePayment() {
    setState(() => isProcessing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: isProcessing ? _buildProcessing() : _buildPaymentUI(controller),
        );
      },
    );
  }

  Widget _buildPaymentUI(ScrollController controller) {
    return ListView(
      controller: controller,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: 90,
          height: 90,
          child:  Image.asset(
            "assets/images/momo_logo.png",
            width: 70,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          widget.planName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          "${widget.amount}₫",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Vui lòng quét mã QR để thanh toán",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),

        const SizedBox(height: 20),

        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code,
              size: 140, // đã nhỏ lại
              color: Colors.purple,
            ),
          ),
        ),

        const SizedBox(height: 30),

        Text(
          "Thời gian còn lại: $countdown giây",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),

        const SizedBox(height: 40),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Hủy",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: simulatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Tôi đã thanh toán",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 80),
      ],
    );
  }


  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.amberAccent),
          SizedBox(height: 20),
          Text(
            "Đang xác nhận giao dịch...",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
