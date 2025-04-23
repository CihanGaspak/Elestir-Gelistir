import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'CommentSheet.dart';

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
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return CommentSheet(post: widget.post);
      },
    );
  }

  void sharePost() {
    final postText = widget.post["text"];
    final content = "$postText";

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.grey.shade300),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post["username"],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(post["date"],
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

                // İlerleme durumu ve üç nokta menüsü
                Row(
                  children: [
                    Row(
                      children: List.generate(3, (index) {
                        final int currentStep = int.tryParse(widget.post["progressStep"].toString()) ?? 0;
                        bool isFilled = index <= currentStep;

                        IconData stepIcon;
                        String label;

                        switch (index) {
                          case 0:
                            stepIcon = Icons.help_outline;
                            label = "Yardım";
                            break;
                          case 1:
                            stepIcon = Icons.autorenew;
                            label = "İşlemde";
                            break;
                          case 2:
                            stepIcon = Icons.check_circle_outline;
                            label = "Çözüldü";
                            break;
                          default:
                            stepIcon = Icons.circle;
                            label = "";
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            children: [
                              Icon(
                                stepIcon,
                                size: 16,
                                color: isFilled ? Colors.orange : Colors.grey.shade400,
                              ),
                              SizedBox(height: 2),
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: isFilled ? Colors.orange : Colors.grey.shade300,
                              ),
                              SizedBox(height: 2),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isFilled ? Colors.orange : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    SizedBox(width: 8),

                    // Menü
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case "edit":
                            break;
                          case "delete":
                            break;
                          case "report":
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: "edit",
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18, color: Colors.black),
                                SizedBox(width: 8),
                                Text("Düzenle"),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: "delete",
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Sil"),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: "report",
                            child: Row(
                              children: [
                                Icon(Icons.report_problem, size: 18, color: Colors.orange),
                                SizedBox(width: 8),
                                Text("Şikayet Et"),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            // İçerik
            Text(post["text"] ?? "", style: TextStyle(fontSize: 16)),
            SizedBox(height: 6),

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
                        isLiked
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        color: isLiked ? Colors.orange.shade600 : Colors.black,
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
                      Text('${post["commentList"].length}'),
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
            ),
          ],
        ),
      ),
    );
  }
}
