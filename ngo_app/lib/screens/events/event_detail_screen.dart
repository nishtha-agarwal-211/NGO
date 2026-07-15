import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 4.
class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Center(child: Text('Event detail for $eventId — coming soon')),
    );
  }
}
