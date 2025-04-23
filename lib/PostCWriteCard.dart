import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostWrite extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String text, String category, File? image) onPost;

  const PostWrite({
    super.key,
    required this.controller,
    required this.onPost,
  });

  @override
  State<PostWrite> createState() => _PostWriteState();
}


class _PostWriteState extends State<PostWrite> {
  String selectedCategory = 'Eğitim';
  File? selectedImage;

  final List<String> categories = ['Eğitim', 'Spor', 'Tamirat', 'Araç Bakım'];

  // Fotoğraf seçme fonksiyonu
  Future<void> pickImage() async {
    final picker = ImagePicker();

    // Fotoğraf seçme işlemi
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    // Eğer fotoğraf seçilmişse
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path); // Fotoğrafı kaydet
      });
    } else {
      // Fotoğraf seçilmediğinde kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraf seçilmedi")),
      );
    }
  }


  // Paylaşma işlemi
  void handlePost() {
    if (widget.controller.text.trim().isEmpty) return;

    widget.onPost(
        widget.controller.text.trim(), selectedCategory, selectedImage);

    setState(() {
      selectedImage = null;
      widget.controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(

      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Kullanıcı adı ve tarih
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.grey.shade300),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kullanıcı Adı", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Tarih", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                // Kategori dropdown (sağ üstte)
                DropdownButton<String>(
                  value: selectedCategory,
                  items: categories
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
              ],
            ),
            Divider(height: 1,),
            TextField(
              controller: widget.controller,
              maxLines: null,
              decoration: InputDecoration.collapsed(
                hintText: "Bir şeyler yaz...",
              ),
            ),
            Divider(height: 1,),
            // Seçilen fotoğraf önizlemesi
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  selectedImage!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Divider(height: 1,),
            // Fotoğraf ekleme ve paylaşma butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.add_photo_alternate, color: Colors.blue.shade600,size: 40,),
                  onPressed: pickImage, // Fotoğraf seçme işlemi
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.orange.shade600,size: 40,),
                  onPressed: handlePost, // Paylaşma işlemi
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

