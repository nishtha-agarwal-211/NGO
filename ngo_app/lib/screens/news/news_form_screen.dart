import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 6.
class NewsFormScreen extends StatelessWidget {
  final String? newsId;

  const NewsFormScreen({super.key, this.newsId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(newsId != null ? 'Edit News Item' : 'Add News Item')),
      body: const Center(child: Text('News form — coming soon')),
    );
  }
}
