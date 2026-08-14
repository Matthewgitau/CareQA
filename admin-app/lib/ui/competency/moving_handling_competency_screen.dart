import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class MovingHandlingCompetencyScreen extends StatelessWidget {
  const MovingHandlingCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'moving_handling',
      competencyName: 'Moving & Handling Competency',
    );
  }
}