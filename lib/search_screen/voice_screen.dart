import 'package:flutter/material.dart';

class VoiceScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const VoiceScreen({super.key, this.onBack});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.onBack != null) widget.onBack!(); // hiện AppBar về lại MainHome
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1C),

        body: SafeArea(
          child: Column(
            children: [
              // ✅ Header (thay thế AppBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () {
                        if (widget.onBack != null) widget.onBack!();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "Tìm kiếm bằng giọng nói",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Nội dung VoiceScreen
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 110,
                        color: Colors.indigoAccent,
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Nhấn để nói",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
