import 'package:flutter/material.dart';

class MarChartViewScreen extends StatelessWidget {
  const MarChartViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAR Chart View')),
      body: const Center(child: Text('Coming soon — MAR Chart View')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}