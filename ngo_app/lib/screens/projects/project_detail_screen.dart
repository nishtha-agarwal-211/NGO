import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 4.
class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: Center(child: Text('Project detail for $projectId — coming soon')),
    );
  }
}
