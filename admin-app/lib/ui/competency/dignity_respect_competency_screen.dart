import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class DignityRespectCompetencyScreen extends StatelessWidget {
  const DignityRespectCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'dignity_respect',
      competencyName: 'Dignity & Respect Competency',
    );
  }
}