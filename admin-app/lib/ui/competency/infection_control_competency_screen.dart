import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class InfectionControlCompetencyScreen extends StatelessWidget {
  const InfectionControlCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'infection_control',
      competencyName: 'Infection Control Competency',
    );
  }
}