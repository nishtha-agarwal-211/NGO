import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 4.
class EventFormScreen extends StatelessWidget {
  final String? eventId;
  final String? projectId;

  const EventFormScreen({super.key, this.eventId, this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(eventId != null ? 'Edit Event' : 'Add Event')),
      body: const Center(child: Text('Event form — coming soon')),
    );
  }
}
