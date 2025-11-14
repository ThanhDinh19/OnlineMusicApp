import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/login_screens/login_demo.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../home_screens/main_home.dart';

class ArtistSelectScreen extends StatefulWidget {
  const ArtistSelectScreen({Key? key}) : super(key: key);

  @override
  State<ArtistSelectScreen> createState() => _ArtistSelectScreenState();
}

class _ArtistSelectScreenState extends State<ArtistSelectScreen> {
  List<dynamic> artists = [];
  List<dynamic> filteredArtists = [];
  List<dynamic> selectedArtists = [];
  bool isLoading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    fetchArtists();
  }

  Future<void> fetchArtists() async {
    try {
      final url = Uri.parse(
          'http://10.0.2.2:8081/music_API/online_music/artist/get_artists.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData["status"] == "success" && jsonData["artists"] != null) {
          setState(() {
            artists = jsonData["artists"];
            filteredArtists = List.from(artists);
            isLoading = false;
          });
        } else {
          throw Exception("Dữ liệu không hợp lệ");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi tải danh sách nghệ sĩ: $e");
      setState(() => isLoading = false);
    }
  }

  void searchArtist(String value) {
    setState(() {
      query = value.toLowerCase();
      filteredArtists = artists
          .where((a) =>
      (a["name"] as String).toLowerCase().contains(query) ||
          (a["bio"] as String).toLowerCase().contains(query))
          .toList();
    });
  }

  void toggleSelection(dynamic artist) {
    setState(() {
      if (selectedArtists.contains(artist)) {
        selectedArtists.remove(artist);
      } else {
        selectedArtists.add(artist); // không giới hạn
      }
    });
  }

  void goToHome() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (selectedArtists.length < 3) { // yêu cầu ít nhất 3
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất 3 nghệ sĩ!")),
      );
      return;
    }

    await saveFavoriteArtists(user!.id.toString());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainHome()),
    );
  }



  Future<void> saveFavoriteArtists(String userId) async {
    final url = Uri.parse(
        "http://10.0.2.2:8081/music_API/online_music/artist/save_favorite_artists.php");

    final response = await http.post(url, body: {
      "user_id": userId.toString(),
      "artist_ids":
      jsonEncode(selectedArtists.map((a) => a["artist_id"]).toList()),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã lưu nghệ sĩ yêu thích thành công!")),
        );
      } else {
        debugPrint("Lỗi lưu nghệ sĩ: ${data["message"]}");
      }
    } else {
      debugPrint("Lỗi HTTP: ${response.statusCode}");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreenDemo()));
          },
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          "Chọn nghệ sĩ yêu thích của bạn",
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(
              child: filteredArtists.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Không tìm thấy nghệ sĩ nào",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredArtists.length,
                itemBuilder: (context, index) {
                  final artist = filteredArtists[index];
                  final isSelected = selectedArtists.contains(artist);
                  return _buildArtistGridCard(artist, isSelected);
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Hãy chọn ít nhất 3 nghệ sĩ bạn yêu thích",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              "Đã chọn: ${selectedArtists.length} nghệ sĩ",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Tìm kiếm nghệ sĩ...",
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFF1A1F36),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: searchArtist,
      ),
    );
  }

  Widget _buildArtistGridCard(dynamic artist, bool isSelected) {
    final avatar = artist["avatar_url"];
    final name = artist["name"];

    return GestureDetector(
      onTap: () => toggleSelection(artist),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                //color: const Color(0xFF1A1F36),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.transparent,
                    blurRadius: 8,
                  ),
                ]
                    : [],
              ),
              child: Stack(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade700,
                      backgroundImage: NetworkImage(avatar),
                      onBackgroundImageError: (_, __) =>
                      const Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedScale(
                      scale: isSelected ? 1.2 : 0.8,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isSelected ? Icons.favorite : Icons.favorite_border,
                          color: isSelected ? Colors.redAccent : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: goToHome,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Tiếp tục",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}