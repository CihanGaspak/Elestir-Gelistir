import 'package:elestir_gelistir/explorepage/popular_categories_widget.dart';
import 'package:elestir_gelistir/explorepage/popular_posts_widget.dart';
import 'package:elestir_gelistir/explorepage/search_bar_widget.dart';
import 'package:elestir_gelistir/explorepage/daily_post_widget.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade600;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keşfet", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SearchBarWidget(),
          SizedBox(height: 16),
          DailyPostWidget(),
          SizedBox(height: 24),
          PopularCategoriesWidget(),
          SizedBox(height: 24),
          PopularPostsWidget(),
        ],
      ),
    );
  }
}
