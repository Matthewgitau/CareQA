import 'package:flutter/material.dart';
import 'competency_list_screen.dart';

class CatheterCareCompetencyScreen extends StatelessWidget {
  const CatheterCareCompetencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompetencyListScreen(
      competencyType: 'catheter_care',
      competencyName: 'Catheter Care Competency',
    );
  }
}