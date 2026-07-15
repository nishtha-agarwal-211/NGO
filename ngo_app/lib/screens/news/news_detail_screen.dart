import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 6.
class NewsDetailScreen extends StatelessWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News Detail')),
      body: Center(child: Text('News detail for $newsId — coming soon')),
    );
  }
}
