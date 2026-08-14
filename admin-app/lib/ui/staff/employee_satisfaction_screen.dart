import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/satisfaction_survey.dart';
import '../../models/staff_recognition.dart';
import '../../services/satisfaction_service.dart';
import 'satisfaction_survey_form.dart';
import 'staff_recognition_form.dart';

class EmployeeSatisfactionScreen extends StatefulWidget {
  const EmployeeSatisfactionScreen({super.key});

  @override
  State<EmployeeSatisfactionScreen> createState() => _EmployeeSatisfactionScreenState();
}

class _EmployeeSatisfactionScreenState extends State<EmployeeSatisfactionScreen> with SingleTickerProviderStateMixin {
  final _service = SatisfactionService(Supabase.instance.client);
  List<SatisfactionSurvey> _surveys = [];
  List<StaffRecognition> _recognitions = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final surveys = await _service.getSurveys();
      final recognitions = await _service.getRecognition();
      if (mounted) {
        setState(() {
          _surveys = surveys;
          _recognitions = recognitions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Satisfaction & Engagement'),
        actions: [
          IconButton(
            onPressed: _addSurvey,
            icon: const Icon(Icons.add),
            tooltip: 'New Survey',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Dashboard Cards
                _buildDashboardCards(),
                // Tab Bar
                Container(
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _selectedIndex = 0),
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedIndex == 0 ? Colors.blue : Colors.transparent,
                            foregroundColor: _selectedIndex == 0 ? Colors.white : Colors.black87,
                          ),
                          child: const Text('Surveys'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _selectedIndex = 1),
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedIndex == 1 ? Colors.blue : Colors.transparent,
                            foregroundColor: _selectedIndex == 1 ? Colors.white : Colors.black87,
                          ),
                          child: const Text('Recognition'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _selectedIndex == 0 ? _buildSurveysList() : _buildRecognitionList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedIndex == 0 ? _addSurvey : _addRecognition,
        child: Icon(_selectedIndex == 0 ? Icons.assignment : Icons.emoji_events),
      ),
    );
  }

  Widget _buildDashboardCards() {
    final avgSatisfaction = _surveys.isNotEmpty
        ? _surveys.map((s) => s.overallSatisfaction ?? 0).reduce((a, b) => a + b) / _surveys.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Avg Satisfaction',
              avgSatisfaction.toStringAsFixed(1),
              avgSatisfaction >= 8 ? Colors.green : avgSatisfaction >= 5 ? Colors.orange : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Surveys',
              _surveys.length.toString(),
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Recognitions',
              _recognitions.length.toString(),
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSurveysList() {
    if (_surveys.isEmpty) {
      return const Center(child: Text('No surveys found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _surveys.length,
      itemBuilder: (context, index) {
        final survey = _surveys[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(survey.getSatisfactionColorValue()),
              child: Text(
                survey.overallSatisfaction?.toString() ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              survey.staffName ?? 'Anonymous',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(survey.getSurveyTypeDisplay()),
                Text('${DateFormat('dd/MM/yyyy').format(survey.surveyDate)} • Avg: ${survey.getAverageScore().toStringAsFixed(1)}/10'),
                if (survey.isAnonymous)
                  const Text('Anonymous', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(survey.getSatisfactionColorValue()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    survey.getSatisfactionStatus(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            onTap: () => _viewSurveyDetails(survey),
          ),
        );
      },
    );
  }

  Widget _buildRecognitionList() {
    if (_recognitions.isEmpty) {
      return const Center(child: Text('No recognitions found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recognitions.length,
      itemBuilder: (context, index) {
        final recognition = _recognitions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.emoji_events, color: Colors.white),
            ),
            title: Text(
              recognition.staffName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recognition.getRecognitionTypeDisplay()),
                Text('${DateFormat('dd/MM/yyyy').format(recognition.recognitionDate)}'),
                Text(recognition.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            onTap: () => _viewRecognitionDetails(recognition),
          ),
        );
      },
    );
  }

  void _viewSurveyDetails(SatisfactionSurvey survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${survey.getSurveyTypeDisplay()} - ${survey.staffName ?? 'Anonymous'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(survey.surveyDate)),
              _buildDetailRow('Overall Satisfaction', '${survey.overallSatisfaction ?? 'N/A'}/10'),
              _buildDetailRow('Engagement', '${survey.engagementScore ?? 'N/A'}/10'),
              _buildDetailRow('Motivation', '${survey.motivationScore ?? 'N/A'}/10'),
              _buildDetailRow('Work Environment', '${survey.workEnvironmentScore ?? 'N/A'}/10'),
              _buildDetailRow('Management Support', '${survey.managementSupportScore ?? 'N/A'}/10'),
              _buildDetailRow('Career Development', '${survey.careerDevelopmentScore ?? 'N/A'}/10'),
              _buildDetailRow('Work-Life Balance', '${survey.workLifeBalanceScore ?? 'N/A'}/10'),
              if (survey.whatDoYouEnjoy != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('What do you enjoy:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(survey.whatDoYouEnjoy!),
              ],
              if (survey.whatCouldImprove != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('What could improve:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(survey.whatCouldImprove!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _viewRecognitionDetails(StaffRecognition recognition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recognition.getRecognitionTypeDisplay()),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${recognition.staffName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(recognition.recognitionDate)),
            _buildDetailRow('Reason', recognition.reason),
            if (recognition.nominatedByName != null)
              _buildDetailRow('Nominated by', recognition.nominatedByName!),
            if (recognition.awardDetails != null)
              _buildDetailRow('Award Details', recognition.awardDetails!),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SatisfactionSurveyFormScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _addRecognition() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StaffRecognitionFormScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }
}