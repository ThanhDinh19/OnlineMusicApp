import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier{
  static final GoogleSignIn googleSignInn = GoogleSignIn(
    serverClientId: '125149603567-mq5qjrs3tsb5sj6b47ppc0re8hboim38.apps.googleusercontent.com',
  );

  static bool _isInitialized = false;

  static Future<void> _initSignIn() async {
    if (!_isInitialized) {
      // Không cần gọi initialize nữa, chỉ cần tạo GoogleSignIn với serverClientId
      _isInitialized = true;
    }
  }

  // for sign in
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // 1️⃣ Bắt đầu đăng nhập Google
      final GoogleSignInAccount? googleUser = await googleSignInn.signIn();

      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        throw FirebaseAuthException(
          code: 'ABORTED-BY-USER',
          message: 'Đăng nhập bị hủy bởi người dùng.',
        );
      }

      // 2️⃣ Lấy token xác thực từ Google
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // 3️⃣ Tạo credential từ token
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4️⃣ Đăng nhập Firebase bằng credential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      rethrow;
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async{
    await googleSignInn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}