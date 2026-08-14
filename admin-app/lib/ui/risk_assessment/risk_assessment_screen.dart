import 'package:flutter/material.dart';
import 'package:admin_app/ui/assessments/falls_risk_screen.dart';
import 'package:admin_app/ui/assessments/choking_risk_screen.dart';
import 'package:admin_app/ui/assessments/medication_risk_screen.dart';
import 'package:admin_app/ui/waterlow_assessment/waterlow_screen.dart';
import 'package:admin_app/ui/assessments/mca_screen.dart';
import 'package:admin_app/ui/risk/self_harm_risk_screen.dart';
import 'package:admin_app/ui/risk/challenging_behaviour_screen.dart';
import 'package:admin_app/ui/risk/bed_railing_screen.dart';
import 'package:admin_app/ui/risk/fire_hazard_screen.dart';
import 'package:admin_app/ui/risk/environmental_risk_screen.dart';
import 'package:admin_app/ui/risk/activity_risk_screen.dart';
import 'package:admin_app/ui/risk/nutrition_risk_screen.dart';

class RiskAssessment {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  const RiskAssessment({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class RiskAssessmentHubScreen extends StatelessWidget {
  const RiskAssessmentHubScreen({super.key});

  List<RiskAssessment> get _clinicalAssessments => [
    RiskAssessment(
      title: 'Falls Risk',
      description: 'Assess risk of falls for service users',
      icon: Icons.accessibility,
      color: Colors.red,
      screen: const FallsRiskScreen(),
    ),
    RiskAssessment(
      title: 'Choking Risk',
      description: 'Evaluate choking hazards and swallowing',
      icon: Icons.lunch_dining,
      color: Colors.orange,
      screen: const ChokingRiskScreen(),
    ),
    RiskAssessment(
      title: 'Medication Risk',
      description: 'Review medication safety and compliance',
      icon: Icons.medication,
      color: Colors.blue,
      screen: const MedicationRiskScreen(),
    ),
    RiskAssessment(
      title: 'Waterlow Assessment',
      description: 'Pressure ulcer risk assessment',
      icon: Icons.airline_seat_recline_normal,
      color: Colors.purple,
      screen: const WaterlowScreen(),
    ),
    RiskAssessment(
      title: 'Mental Capacity (MCA)',
      description: 'Assess mental capacity and decision-making',
      icon: Icons.psychology,
      color: Colors.teal,
      screen: const McaScreen(),
    ),
  ];

  List<RiskAssessment> get _behaviouralAssessments => [
    RiskAssessment(
      title: 'Self Harm Risk',
      description: 'Identify and manage self-harm behaviors',
      icon: Icons.self_improvement,
      color: Colors.deepOrange,
      screen: const SelfHarmRiskScreen(),
    ),
    RiskAssessment(
      title: 'Challenging Behaviour',
      description: 'Assess and manage challenging behaviors',
      icon: Icons.psychology_alt,
      color: Colors.brown,
      screen: const ChallengingBehaviourScreen(),
    ),
  ];

  List<RiskAssessment> get _safetyAssessments => [
    RiskAssessment(
      title: 'Bed Railing Risk',
      description: 'Evaluate need for bed rails and safety',
      icon: Icons.bed,
      color: Colors.indigo,
      screen: const BedRailingScreen(),
    ),
    RiskAssessment(
      title: 'Fire Hazard',
      description: 'Identify fire risks and prevention measures',
      icon: Icons.local_fire_department,
      color: Colors.red,
      screen: const FireHazardScreen(),
    ),
    RiskAssessment(
      title: 'Environmental Risk',
      description: 'Assess environmental hazards and safety',
      icon: Icons.eco,
      color: Colors.teal,
      screen: const EnvironmentalRiskScreen(),
    ),
    RiskAssessment(
      title: 'Activity Risk',
      description: 'Evaluate risks during activities',
      icon: Icons.sports,
      color: Colors.orange,
      screen: const ActivityRiskScreen(),
    ),
  ];

  List<RiskAssessment> get _healthAssessments => [
    RiskAssessment(
      title: 'Nutrition Risk',
      description: 'Evaluate nutritional status and needs',
      icon: Icons.restaurant,
      color: Colors.green,
      screen: const NutritionRiskScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessments'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, 'Clinical Risk Assessments', Icons.medical_services, _clinicalAssessments),
          const SizedBox(height: 16),
          _buildSection(context, 'Behavioural Risk Assessments', Icons.psychology, _behaviouralAssessments),
          const SizedBox(height: 16),
          _buildSection(context, 'Safety Risk Assessments', Icons.shield, _safetyAssessments),
          const SizedBox(height: 16),
          _buildSection(context, 'Health Risk Assessments', Icons.monitor_heart, _healthAssessments),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<RiskAssessment> assessments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: assessments.length,
          itemBuilder: (context, index) {
            final assessment = assessments[index];
            return _buildAssessmentCard(context, assessment);
          },
        ),
      ],
    );
  }

  Widget _buildAssessmentCard(BuildContext context, RiskAssessment assessment) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => assessment.screen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: assessment.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(assessment.icon, color: assessment.color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                assessment.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}