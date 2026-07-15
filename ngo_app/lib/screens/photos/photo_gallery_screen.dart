import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 5.
class PhotoGalleryScreen extends StatelessWidget {
  final String eventId;

  const PhotoGalleryScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Gallery')),
      body: Center(child: Text('Photo gallery for event $eventId — coming soon')),
    );
  }
}
