import 'package:flutter/material.dart';

class MeetingsLogScreen extends StatelessWidget {
  const MeetingsLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings Log')),
      body: const Center(child: Text('Coming soon — Meetings Log')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}