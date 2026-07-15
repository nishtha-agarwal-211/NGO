import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 2.
class MemberDetailScreen extends StatelessWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: Center(child: Text('Member detail for $memberId — coming soon')),
    );
  }
}
