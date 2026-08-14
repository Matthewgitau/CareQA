import 'package:flutter/material.dart';

class SupervisionMatrixScreen extends StatelessWidget {
  const SupervisionMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supervision Matrix')),
      body: const Center(child: Text('Coming soon — Supervision Matrix')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}