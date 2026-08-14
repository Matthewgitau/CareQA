import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class FireSafetyCompetencyScreen extends StatelessWidget {
  const FireSafetyCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'fire_safety',
      competencyName: 'Fire Safety Competency',
    );
  }
}