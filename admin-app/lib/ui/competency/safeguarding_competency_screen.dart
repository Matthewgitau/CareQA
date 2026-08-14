import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class SafeguardingCompetencyScreen extends StatelessWidget {
  const SafeguardingCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'safeguarding',
      competencyName: 'Safeguarding Competency',
    );
  }
}