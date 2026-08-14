import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class CommunicationCompetencyScreen extends StatelessWidget {
  const CommunicationCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'communication',
      competencyName: 'Communication Competency',
    );
  }
}