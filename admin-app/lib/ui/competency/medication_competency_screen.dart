import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class MedicationCompetencyScreen extends StatelessWidget {
  const MedicationCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'medication',
      competencyName: 'Medication Competency',
    );
  }
}