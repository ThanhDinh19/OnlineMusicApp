import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ads/ad_audio_screen.dart';
import '../main.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  String? playlistName; // để tạm
  String? playlistId;

  List<Map<String, dynamic>> playlist = [];
  int currentIndex = 0;
  bool isPlaying = false;
  bool isPlaying1 = false; // để đồng nhất với trạng thái của miniplayer (playlist_detail_screen)


  bool isShuffle = false;
  bool isRepeat = false;

  String? currentSongId;
  String? currentSongPath;
  String? currentTitle;
  String? currentArtist;
  String? currentCover;


  AudioPlayerProvider(BuildContext context) {
    _init(context);
  }

  Future<void> _init(BuildContext context) async {
    await loadLastSong();
    await _loadSongCount();
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongEnd();
      }
    });
  }

  Future<void> _loadSongCount() async {
    final prefs = await SharedPreferences.getInstance();
    song_count = prefs.getInt('song_count') ?? 0;
  }


  // Helper: lấy UID hiện tại
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? "guest";

  AudioPlayer get adPlayer => _adPlayer;

  Future<void> setSong({
    required String id,
    required String path,
    required String title,
    required String artist,
    required String cover,
  }) async {
    currentIndex = 0;
    await player.setAsset(path);
    currentSongId = id;
    currentSongPath = path;
    currentTitle = title;
    currentArtist = artist;
    currentCover = cover;

    await _saveLastSong();
    notifyListeners();
  }


  void setPlaying(bool playing) {
    isPlaying = playing;
    isPlaying1 = playing;
    notifyListeners();
  }

  void setCurrentSong(int songId) {
    currentIndex = songId;
    notifyListeners();
  }

  bool isPremium = false;
  int song_count = 0;

  Future<bool> checkPremiumStatus() async {
    final ctx = navigatorKey.currentContext;
    final userProvider = Provider.of<UserProvider>(ctx!, listen: false);
    final userId = userProvider.user!.id.toString();
    try {
      final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/ads/check_premium_status.php?user_id=$userId",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == "success") {
          return data["is_premium"];
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi kiểm tra premium: $e");
    }
    return false; // Mặc định là user free nếu có lỗi
  }

  Future<void> checkAndUpdatePremium() async {
    if (_userId == null) return;
    final result = await checkPremiumStatus();
    isPremium = result;
    notifyListeners();
  }

  Future<void> _increaseSongCount() async {
    song_count++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('song_count_$_userId', song_count);
  }

  Future<void> saveListeningHistory() async {
    try {
      final ctx = navigatorKey.currentContext;
      final userProvider = Provider.of<UserProvider>(ctx!, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null || currentSongId == null) {
        debugPrint("Không có userId hoặc songId để lưu lịch sử");
        return;
      }

      final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/history/save_listening_history.php",
      );

      final response = await http.post(url, body: {
        "user_id": userId.toString(),
        "song_id": currentSongId.toString(),
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("${data["message"]}");
      } else {
        debugPrint("Server error khi lưu lịch sử: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi khi lưu lịch sử nghe: $e");
    }
  }

  Future<void> _saveLastSong() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('songId_$_userId', currentSongId ?? '');
    await prefs.setString('songPath_$_userId', currentSongPath ?? '');
    await prefs.setString('songTitle_$_userId', currentTitle ?? '');
    await prefs.setString('songArtist_$_userId', currentArtist ?? '');
    await prefs.setString('songCover_$_userId', currentCover ?? '');
  }

  Future<void> loadLastSong() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('songPath_$_userId');
    if (path != null && path.isNotEmpty) {
      currentSongPath = path;
      currentSongId = prefs.getString('songId_$_userId');
      currentTitle = prefs.getString('songTitle_$_userId');
      currentArtist = prefs.getString('songArtist_$_userId');
      currentCover = prefs.getString('songCover_$_userId');
      await player.setAudioSource(AudioSource.uri(Uri.parse(currentSongPath!)));
      notifyListeners();
    }
  }

  Future<void> clearSong() async {
    await player.stop();
    currentSongId = null;
    currentSongPath = null;
    currentTitle = null;
    currentArtist = null;
    currentCover = null;


    playlist = [];
    playlistId = "";
    playlistName = "";

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('songId_$_userId');
    await prefs.remove('songPath_$_userId');
    await prefs.remove('songTitle_$_userId');
    await prefs.remove('songArtist_$_userId');
    await prefs.remove('songCover_$_userId');
    await prefs.remove('song_count_$_userId');


    notifyListeners();
  }

  // set playlist online
  Future<void> setPlaylist(List<Map<String, dynamic>> songs, {int startIndex = 0, int statusIndex = 0}) async {
    playlist = songs;
    currentIndex = startIndex;
    if(isShuffle == true && statusIndex == 0){
      shufflePlaying();
      await _loadCurrentSong_();
    }
    else{
      await _loadCurrentSong_();
    }
  }

  // load để phát online
  Future<void> _loadCurrentSong_() async {
    final song = playlist[currentIndex];
    currentSongId = song['song_id'].toString();
    currentSongPath = song['audio_url'];
    currentTitle = song['title'];
    currentArtist = song['artist'] ?? song["artist_name"];
    currentCover = song['cover_url'];

    await player.setAudioSource(AudioSource.uri(Uri.parse(currentSongPath!)));

    player.play();

    await saveListeningHistory();

    await _saveLastSong();
    notifyListeners();
  }

  // set playlist offline
  Future<void> setOfflinePlaylist(List<Map<String, dynamic>> songs, {int startIndex = 0, int statusIndex = 0}) async {
    playlist = songs;
    currentIndex = startIndex;
    if(isShuffle == true && statusIndex == 0){
      shufflePlaying();
      await _loadCurrentSong();
    }
    else{
      await _loadCurrentSong();
    }
  }

  // load để phát offline
  Future<void> _loadCurrentSong() async {
    if (playlist.isEmpty || currentIndex < 0 || currentIndex >= playlist.length) {
      debugPrint("Playlist trống hoặc chỉ số không hợp lệ");
      return;
    }

    final song = playlist[currentIndex];
    currentSongId = song['song_id'].toString();
    currentSongPath = song["local_path"];
    currentTitle = song['title'];
    currentArtist = song['artist'] ?? song["artist_name"];
    currentCover = song['cover_url'];

    if (currentSongPath == null || currentSongPath!.isEmpty) {
      debugPrint("currentSongPath bị null hoặc rỗng: $song");
      return;
    }

    await player.setFilePath(currentSongPath!);
    await player.play();

    await _saveLastSong();
    notifyListeners();
  }

  Future<void> _handleSongEnd() async {
    if (isRepeat) {
      await player.seek(Duration.zero);
      await player.play();
    } else if (isShuffle) {
      final random = Random();
      int nextIndex;
      do {
        nextIndex = random.nextInt(playlist.length);
      } while (nextIndex == currentIndex && playlist.length > 1);
      currentIndex = nextIndex;
      await _loadCurrentSong_();
    } else {
      if (currentIndex < playlist.length - 1) {
        currentIndex++;
        await _loadCurrentSong_();
      } else {
        await player.stop();
        return;
      }
    }

    // ✅ Tăng số bài và kiểm tra quảng cáo
    await _increaseSongCount();
    await checkAndUpdatePremium();

    if (!isPremium && song_count % 2 == 0) {
      debugPrint("📢 Phát quảng cáo sau bài thứ $song_count");
      await playAd();
    }
  }

  Future<void> shufflePlaying() async {
    final random = Random();
    int nextIndex;
    do {
      nextIndex = random.nextInt(playlist.length);
    } while (nextIndex == currentIndex && playlist.length > 1);
    currentIndex = nextIndex;
  }

  Future<void> playNext() async {
    if (playlist.isEmpty) return;

    if (isShuffle) {
      currentIndex = Random().nextInt(playlist.length);
    } else {
      currentIndex = (currentIndex + 1) % playlist.length;
    }

    await _loadCurrentSong_();

    // Đếm số bài & phát quảng cáo nếu đủ
    await _increaseSongCount();
    await checkAndUpdatePremium();
    if (isPremium == false && song_count % 2 == 0) {
      print("=================== =============== =================== =============== ============");
      print(song_count);
      print(isPremium);
      await playAd();
    }
    await saveListeningHistory();
  }

  Future<void> playPrevious() async {
    if (playlist.isEmpty) return;

    if (isShuffle) {
      currentIndex = Random().nextInt(playlist.length);
    } else {
      currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    }

    await _loadCurrentSong_();

    await _increaseSongCount();
    await checkAndUpdatePremium();
    if (isPremium == false && song_count % 2 == 0) {
      await playAd();
    }
    await saveListeningHistory();
  }

  // hàm lặp lại bài, lưu status vào prefs để khi mở lại screen hoặc khi thoát màn hình và vào lại thì
  // vẫn còn giữ trạng thái
  void toggleRepeat() async {
    isRepeat = !isRepeat;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRepeat_$_userId', isRepeat);
  }

  // tương tự như lặp lại bài
  void toggleShuffle() async {
    isShuffle = !isShuffle;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isShuffle_$_userId', isShuffle);
  }

  // dùng để lưu lại status của shuffle và repeat, khi thoát app và mở lại thì vẫn còn giữ trạng thái
  Future<void> loadLastSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isRepeat = prefs.getBool('isRepeat_$_userId') ?? false;
    isShuffle = prefs.getBool('isShuffle_$_userId') ?? false;
    notifyListeners();
  }

  /// ==================== PHẦN QUẢNG CÁO ====================
  Map<String, dynamic>? currentAd; // Lưu quảng cáo đang phát
  bool isAdPlaying = false;

  /// Hàm lấy ngẫu nhiên quảng cáo từ server
  Future<Map<String, dynamic>?> _fetchRandomAd() async {
    try {
      final res = await http.get(
        Uri.parse("http://10.0.2.2:8081/music_API/online_music/ads/get_ads.php"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final ads = data["ads"];
        if (ads != null && ads.isNotEmpty) {
          final randomAd = ads[Random().nextInt(ads.length)];
          debugPrint("Chọn quảng cáo: ${randomAd["title"]}");
          return randomAd;
        } else {
          debugPrint("Không có quảng cáo khả dụng từ server");
        }
      } else {
        debugPrint("Lỗi server quảng cáo: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy quảng cáo: $e");
    }
    return null;
  }
  final AudioPlayer _adPlayer = AudioPlayer();

  /// Phát quảng cáo, tạm dừng nhạc đang nghe
  Future<void> playAd() async {
    if (isAdPlaying) {
      debugPrint("Quảng cáo đang phát, bỏ qua...");
      return;
    }

    isAdPlaying = true;
    notifyListeners();

    debugPrint("🎧 Bắt đầu phát quảng cáo...");

    // Lưu bài hát hiện tại
    final previousSongPath = currentSongPath;

    // Dừng nhạc chính nếu đang phát
    if (player.playing) {
      await player.pause();
      debugPrint("Dừng nhạc chính để phát quảng cáo");
    }

    // Lấy quảng cáo ngẫu nhiên
    final ad = await _fetchRandomAd();
    if (ad == null) {
      debugPrint("Không có quảng cáo để phát");
      isAdPlaying = false;
      notifyListeners();
      return;
    }

    currentAd = ad;
    notifyListeners();

    // Lấy context toàn cục
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint("Không tìm thấy context hợp lệ");
      isAdPlaying = false;
      currentAd = null;
      notifyListeners();
      return;
    }

    // Mở màn hình quảng cáo
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => const AdAudioScreen(),
        fullscreenDialog: true,
      ),
    );

    try {
      // Phát quảng cáo bằng player riêng
      await _adPlayer.setUrl(ad["audio_url"]);
      await _adPlayer.play();

      debugPrint("Đang phát quảng cáo: ${ad["title"]}");

      // Đợi quảng cáo phát xong
      await _adPlayer.processingStateStream.firstWhere(
            (state) => state == ProcessingState.completed,
      );

      debugPrint("Quảng cáo phát xong");

      // Đóng màn hình quảng cáo
      if (Navigator.canPop(ctx)) Navigator.pop(ctx);

      // Reset trạng thái quảng cáo
      isAdPlaying = false;
      currentAd = null;
      notifyListeners();

      // Resume lại bài nhạc chính
      if (previousSongPath != null && previousSongPath.isNotEmpty) {
        await player.play();
        debugPrint("Tiếp tục phát nhạc chính sau quảng cáo");
      }
    } catch (e) {
      debugPrint("Lỗi khi phát quảng cáo: $e");

      isAdPlaying = false;
      currentAd = null;
      notifyListeners();

      // Dự phòng: Resume lại nhạc nếu quảng cáo lỗi
      if (previousSongPath != null && previousSongPath.isNotEmpty) {
        await player.play();
      }

      if (Navigator.canPop(ctx)) Navigator.pop(ctx);
    }
  }

  @override
  void dispose() {
    player.stop();
    player.dispose();
    _adPlayer.stop();
    _adPlayer.dispose();
    super.dispose();
  }

}
