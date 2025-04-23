import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'PostCard.dart'; // PostCard bileşenini dahil et

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  File? _coverImage;
  String name = "Cihan Gaspak";
  String username = "@cihangaspak";
  String bio = "Herşeyi az bir şeyi çok biliyor :) 💪";
  int solutions = 18;
  int supports = 45;
  double helpfulness = 8.7;
  int followers = 1200;
  int following = 148;

  List<dynamic> allPosts = [];

  // Simulate fetching posts from local file or assets
  Future<void> loadPosts() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/posts.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          allPosts = json.decode(contents);
        });
      } else {
        // Eğer asset'ten yüklemek gerekiyorsa
        final assetData = await rootBundle.loadString('assets/posts.json');
        setState(() {
          allPosts = json.decode(assetData);
        });
        await savePosts();
      }
    } catch (e) {
      print("Postları yüklerken hata: $e");
    }
  }

  Future<void> savePosts() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/posts.json');
    await file.writeAsString(json.encode(allPosts));
  }

  @override
  void initState() {
    super.initState();
    loadPosts(); // Postları yükle
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }
  Future<void> pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _coverImage = File(picked.path);
      });
    }
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Profil",style: TextStyle(color: Colors.white),),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.orange.shade600,
          // geri tuşunu kaldırır
          actions: [
            IconButton(
              icon: Icon(Icons.settings,size: 30,color: Colors.white,),
              onPressed: () {
                // Ayarlar sayfasını açmak için istediğiniz navigasyon işlemi burada yapılabilir
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()), // Ayarlar sayfasını buraya ekleyin
                );*/
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              // Arka plan (kapak) fotoğrafı
                              GestureDetector(
                                onTap: pickCoverImage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8), // köşe yuvarlama
                                  child: Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: _coverImage != null
                                            ? FileImage(_coverImage!)
                                            : AssetImage("assets/images/cover.jpg") as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(Icons.camera_alt, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Profil fotoğrafı
                              Positioned(
                                bottom:2,
                                left: 2,
                                child: GestureDetector(
                                  onTap: pickProfileImage,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                          border: Border.all(color: Colors.orange.shade600,width: 2),
                                      image: DecorationImage(
                                        image: _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : AssetImage("assets/images/profile.jpg") as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 60), // Profil fotoğrafı taşmasından dolayı boşluk bırak

                          Text(name,
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(username,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                          SizedBox(height: 8),
                          Text(bio, style: TextStyle(fontSize: 14)),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat("Takipçi", followers),
                              _buildStat("Takip", following),
                              _buildStat("Faydalılık",
                                  "${helpfulness.toStringAsFixed(1)}/10"),
                              _buildStat("Destekler", supports),
                            ],
                          ),
                          SizedBox(height: 16),

                          // ⬇️ TabBar'ı buraya ekliyoruz
                          TabBar(
                            labelColor: Colors.orange.shade600,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.orange.shade600,
                            tabs: [
                              Tab(
                                  icon: Icon(Icons.timelapse),
                                  text: "Devam Ed. ($supports)"),
                              Tab(
                                  icon: Icon(Icons.check_circle_outline),
                                  text: "Çözülenler ($solutions)"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _buildOngoingPostList(),
                    _buildSolutionList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String title, dynamic value) {
    return Column(
      children: [
        Text("$value",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(title, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildOngoingPostList() {
    return ListView.builder(
      padding: EdgeInsets.all(0), // Sadece dikey padding'i sıfırladık
      itemCount: allPosts.length,
      itemBuilder: (context, index) {
        final post = allPosts[index];
        return PostCard(post: post); // PostCard widget'ına post'u gönder
      },
    );
  }

  Widget _buildSolutionList() {
    return ListView.builder(
      padding: EdgeInsets.all(4),
      itemCount: solutions,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("Çözüm ${index + 1}"),
            subtitle: Text("Sorun başarılı şekilde çözülmüş."),
          ),
        );
      },
    );
  }
}
