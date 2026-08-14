import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class FirstAidCompetencyScreen extends StatelessWidget {
  const FirstAidCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'first_aid',
      competencyName: 'First Aid Competency',
    );
  }
}