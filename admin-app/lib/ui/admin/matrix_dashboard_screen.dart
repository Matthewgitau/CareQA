import 'package:flutter/material.dart';
import 'package:admin_app/ui/staff/supervision_matrix_screen.dart';
import 'package:admin_app/ui/staff/appraisals_screen.dart';
import 'package:admin_app/ui/staff/training_matrix_screen.dart';

class MatrixDashboardScreen extends StatelessWidget {
  const MatrixDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrix Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Training Matrix'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingMatrixScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.supervisor_account),
              title: const Text('Supervision Matrix'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisionMatrixScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.star_rate),
              title: const Text('Appraisals'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppraisalsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}