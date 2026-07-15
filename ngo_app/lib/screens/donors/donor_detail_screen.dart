import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 3.
class DonorDetailScreen extends StatelessWidget {
  final String donorId;

  const DonorDetailScreen({super.key, required this.donorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Details')),
      body: Center(child: Text('Donor detail for $donorId — coming soon')),
    );
  }
}
