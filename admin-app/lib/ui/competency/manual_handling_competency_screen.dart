import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class ManualHandlingCompetencyScreen extends StatelessWidget {
  const ManualHandlingCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'manual_handling',
      competencyName: 'Manual Handling Competency',
    );
  }
}