import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 4.
class ProjectFormScreen extends StatelessWidget {
  final String? projectId;

  const ProjectFormScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(projectId != null ? 'Edit Project' : 'Add Project')),
      body: const Center(child: Text('Project form — coming soon')),
    );
  }
}
