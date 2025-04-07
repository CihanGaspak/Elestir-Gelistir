import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCard({required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likeCount;
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post["likes"];
    isLiked = false;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  void showComments() {
    final TextEditingController _commentController = TextEditingController();

    // Eğer commentList null ise, boş bir liste atanıyor
    List<Map<String, dynamic>> comments = List<Map<String, dynamic>>.from(
      widget.post["commentList"] ?? [], // commentList null ise boş listeye dönüşüyor
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SizedBox(
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: comments.isEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Henüz yorum yapılmadı.", style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 10),
                      Text("0", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                      : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("${comment["name"]} ${comment["surname"]}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment["text"]),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(comment["date"], style: TextStyle(fontSize: 12, color: Colors.grey)),
                                SizedBox(width: 12),
                                Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text("${comment["likes"] ?? 0}", style: TextStyle(fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "Yorum yaz...",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        final newCommentText = _commentController.text.trim();
                        if (newCommentText.isNotEmpty) {
                          final newComment = {
                            "text": newCommentText,
                            "name": "Sen", // Buraya giriş yapan kullanıcının adı gelecek
                            "surname": "Kullanıcı",
                            "date": DateTime.now().toString().split(" ")[0],
                            "likes": 0,
                          };
                          setState(() {
                            comments.add(newComment);
                            widget.post["commentList"] = comments;  // Güncel yorumları geri yazıyoruz
                            widget.post["comments"] = comments.length; // Yorum sayısını dinamik olarak güncelliyoruz
                          });
                          _commentController.clear();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void sharePost() {
    final postText = widget.post["text"];
    final hashtags = (widget.post["hashtags"] as List<dynamic>?)?.map((e) => "#$e").join(" ") ?? "";

    final content = "$postText\n\n$hashtags";

    Share.share(content);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı adı ve tarih
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.grey.shade300),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post["username"], style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(post["date"], style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),

            // İçerik
            Text(post["text"] ?? "", style: TextStyle(fontSize: 16)),
            SizedBox(height: 6),

            // Hashtagler
            if (post["hashtags"] != null)
              Wrap(
                spacing: 8,
                children: (post["hashtags"] as List<dynamic>)
                    .map((tag) => Text("#$tag", style: TextStyle(color: Colors.blue)))
                    .toList(),
              ),

            // Opsiyonel görsel
            if (post.containsKey("image"))
              Container(
                margin: EdgeInsets.only(top: 10),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(post["image"]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            SizedBox(height: 10),

            // Etkileşim simgeleri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                        color: isLiked ? Colors.blue : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text('$likeCount'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: showComments,
                  child: Row(
                    children: [
                      Icon(Icons.comment_outlined, size: 20),
                      SizedBox(width: 4),
                      Text('${post["commentList"].length}'), // Dynamic comment count
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: sharePost,
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 20),
                      SizedBox(width: 4),
                      Text('${post["shares"]}'),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

