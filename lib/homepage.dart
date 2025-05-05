import 'package:flutter/material.dart';
import 'PostListView.dart'; // Yeni dosya

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<PostListViewState> _postListKey = GlobalKey();

  final List<String> categories = [
    'Tümü', 'Eğitim', 'Spor', 'Tamirat', 'Araç Bakım',
    'Sağlık', 'Teknoloji', 'Kişisel Gelişim', 'Sanat', 'Yazılım',
  ];

  String selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text('Eleştir - Geliştir'),
      ),
      body: Column(
        children: [
          // Kategori butonları
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    selectedColor: primaryColor,
                    onSelected: (_) {
                      if (selectedCategory != cat) {
                        setState(() {
                          selectedCategory = cat;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // PostListView
          Expanded(
            child: PostListView(
              key: _postListKey,
              category: selectedCategory,
            ),
          ),
        ],
      ),
    );
  }
}
