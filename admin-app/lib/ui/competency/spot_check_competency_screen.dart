import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class SpotCheckCompetencyScreen extends StatelessWidget {
  const SpotCheckCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'spot_check',
      competencyName: 'Spot Check Competency',
    );
  }
}