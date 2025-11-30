

class S {
  static String userName(lang, String name) {
    if (lang == "vi") return name; // giữ dấu
    return removeVietnameseTones(name); // bỏ dấu
  }

  static String homeTitle(lang) =>
      lang == "vi" ? "Trang chủ" : "Home";

  static String playlist(lang) =>
      lang == "vi" ? "Danh sách phát" : "Playlist";

  static String settings(lang) =>
      lang == "vi" ? "Cài đặt" : "Settings";

  static String language(lang) =>
      lang == "vi" ? "Chuyển sang Tiếng Anh" : "Switch to Vietnamese";

  static String english(lang) =>
      lang == "vi" ? "Tiếng Anh" : "English";

  static String vietnamese(lang) =>
      lang == "vi" ? "Tiếng Việt" : "Vietnamese";

  static String theme(lang) =>
      lang == "vi" ? "Chủ đề" : "Theme";

  static String notification(lang) =>
      lang == "vi" ? "Thông báo" : "Notification";

  static String support(lang) =>
      lang == "vi" ? "Trợ giúp & Hỗ trợ" : "Help & Support";

  static String logout(lang) =>
      lang == "vi" ? "Đăng xuất" : "Log out";
}

String removeVietnameseTones(String str) {
  str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');

  str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
  str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
  str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
  str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
  str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
  str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
  str = str.replaceAll(RegExp(r'[Đ]'), 'D');

  return str;
}
