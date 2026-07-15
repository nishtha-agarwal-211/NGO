import 'package:flutter/material.dart';

/// Placeholder — will be built in Milestone 3.
class DonorFormScreen extends StatelessWidget {
  final String? donorId;

  const DonorFormScreen({super.key, this.donorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(donorId != null ? 'Edit Donor' : 'Add Donor')),
      body: const Center(child: Text('Donor form — coming soon')),
    );
  }
}
