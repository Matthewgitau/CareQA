import 'package:flutter/material.dart';

class GenerateReportScreen extends StatelessWidget {
  const GenerateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
      body: const Center(child: Text('Coming soon — Report Generation')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}