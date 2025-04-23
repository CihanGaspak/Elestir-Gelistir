import 'package:flutter/material.dart';

class CommentSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const CommentSheet({Key? key, required this.post}) : super(key: key);

  @override
  _CommentSheetState createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  late List<Map<String, dynamic>> comments;

  @override
  void initState() {
    super.initState();
    comments = List<Map<String, dynamic>>.from(
      widget.post["commentList"] ?? [],
    );

    // Her yorum için 'liked' alanı yoksa ekle
    for (var comment in comments) {
      comment["liked"] ??= false;
    }
  }

  void toggleLike(int index) {
    setState(() {
      bool liked = comments[index]["liked"];
      comments[index]["liked"] = !liked;
      if (liked) {
        comments[index]["likes"] = (comments[index]["likes"] ?? 1) - 1;
      } else {
        comments[index]["likes"] = (comments[index]["likes"] ?? 0) + 1;
      }
    });
  }

  void addComment() {
    final newCommentText = _commentController.text.trim();
    if (newCommentText.isNotEmpty) {
      final newComment = {
        "text": newCommentText,
        "name": "Sen",
        "surname": "Kullanıcı",
        "date": DateTime.now().toString().split(" ")[0],
        "likes": 0,
        "liked": false,
      };

      setState(() {
        comments.add(newComment);
        widget.post["commentList"] = comments;
        widget.post["comments"] = comments.length;
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Text("Yorumlar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10),
            Expanded(
              child: comments.isEmpty
                  ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Henüz yorum yapılmadı.",
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 10),
                ],
              )
                  : ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade300,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text:
                                      "${comment["name"]} ${comment["surname"]} ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: comment["text"],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                comment["date"],
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => toggleLike(index),
                              child: Icon(
                                comment["liked"]
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: comment["liked"]
                                    ? Colors.orange.shade600
                                    : Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${comment["likes"] ?? 0}",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Yorum yaz...",
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Colors.orange.shade600,
                  ),
                  onPressed: addComment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}