import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class PressurePreventionCompetencyScreen extends StatelessWidget {
  const PressurePreventionCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'pressure_prevention',
      competencyName: 'Pressure Prevention Competency',
    );
  }
}