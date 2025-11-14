import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = ThemeData(
    scaffoldBackgroundColor:  Color(0xFF1E201E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F0F1C),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E201E),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    useMaterial3: true,
  );

  ThemeData get theme => _currentTheme;

  void setCustomColor(Color color, Color textColor) {
    _currentTheme = ThemeData(
      scaffoldBackgroundColor: color,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.dark,
        primary: color,
        onPrimary: textColor,
        onSurface: textColor,
      ),

      // 🔹 Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: color,
        surfaceTintColor: color,
        scrimColor: Colors.black.withOpacity(0.5),
      ),

      // 🔹 AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // 🔹 Texts toàn hệ thống
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor.withOpacity(0.85)),
        titleLarge: TextStyle(color: textColor),   // <-- title trong Card, ListTile
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: textColor.withOpacity(0.9)),
      ),

      // 🔹 Icon màu theo text
      iconTheme: IconThemeData(color: textColor),

      // 🔹 ListTile
      listTileTheme: ListTileThemeData(
        iconColor: textColor,
        textColor: textColor,
      ),

      // 🔹 Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor, // text/icon
          backgroundColor: color.withOpacity(0.2),
        ),
      ),

      // 🔹 Input, TextField
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
        labelStyle: TextStyle(color: textColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: color.withOpacity(0.5),
        modalBackgroundColor: color.withOpacity(0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      useMaterial3: true,
    );

    notifyListeners();
  }
}
