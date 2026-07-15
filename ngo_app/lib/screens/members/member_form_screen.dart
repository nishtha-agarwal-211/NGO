import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 2.
class MemberFormScreen extends StatelessWidget {
  final String? memberId;

  const MemberFormScreen({super.key, this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(memberId != null ? 'Edit Member' : 'Add Member')),
      body: Center(child: Text('Member form — coming soon')),
    );
  }
}
