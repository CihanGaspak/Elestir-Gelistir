import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../UserProfilePage.dart';

class SearchUserWidget extends StatefulWidget {
  final ValueChanged<String> onClose;
  const SearchUserWidget({super.key, required this.onClose});

  @override
  State<SearchUserWidget> createState() => _SearchUserWidgetState();
}

class _SearchUserWidgetState extends State<SearchUserWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = "";
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();

    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    final list = List<String>.from(data?['searchHistory'] ?? []);
    setState(() => _history = list);
  }

  Future<void> _updateHistory(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > 5) _history = _history.sublist(0, 5);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'searchHistory': _history
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => widget.onClose(""),
        ),
        title: TextField(
          focusNode: _focusNode,
          controller: _controller,
          onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
          onSubmitted: (val) {
            _updateHistory(val.trim());
            setState(() => _query = val.trim().toLowerCase());
          },
          decoration: InputDecoration(
            hintText: 'Kullanıcı adına göre ara...',
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.red,),
              onPressed: () {
                _controller.clear();
                setState(() => _query = "");
              },
            )
                : null,
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildSearchHistory(primaryColor)
          : _buildSearchResults(),
    );
  }

  Widget _buildSearchHistory(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _history.isEmpty
          ? const Center(child: Text("Henüz arama geçmişiniz yok."))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Son Aramalar", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._history.map((h) {
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(h),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  _history.remove(h);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'searchHistory': _history});
                  setState(() {});
                },
              ),
              onTap: () {
                setState(() {
                  _controller.text = h;
                  _query = h.toLowerCase();
                });
              },
            );
          }),
        ],
      ),
    );
  }


  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['username'] ?? '').toString().toLowerCase();
          return name.contains(_query);
        }).toList();

        if (results.isEmpty) return const Center(child: Text("Sonuç bulunamadı."));

        return ListView(
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final username = data['username'] ?? "Kullanıcı";
            final photo = data['photoUrl'] ?? "assets/default_avatar.png";

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: photo.startsWith("assets/")
                        ? AssetImage(photo) as ImageProvider
                        : NetworkImage(photo),
                  ),
                  title: Text(username),
                  onTap: () {
                    _updateHistory(username);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserProfilePage(userId: doc.id)),
                    );
                  },
                ),
                // Divider fotonun alt hizasından başlasın
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: Divider(
                    color: Color(0xFFDDDDDD), // açık gri
                    thickness: 1,
                    height: 0,
                  ),
                ),
              ],
            );
          }).toList(),
        );


      },
    );
  }
}
