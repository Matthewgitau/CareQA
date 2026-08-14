import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/domiciliary_fire_safety_assessment.dart';
import '../../services/domiciliary_fire_safety_service.dart';
import 'domiciliary_fire_safety_form.dart';

class FireHazardScreen extends StatefulWidget {
  final String? serviceUserId;

  const FireHazardScreen({Key? key, this.serviceUserId}) : super(key: key);

  @override
  _FireHazardScreenState createState() => _FireHazardScreenState();
}

class _FireHazardScreenState extends State<FireHazardScreen> {
  final _service = DomiciliaryFireSafetyService(Supabase.instance.client);
  late Future<List<DomiciliaryFireSafetyAssessment>> _assessmentsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _assessmentsFuture = _loadAssessments();
  }

  Future<List<DomiciliaryFireSafetyAssessment>> _loadAssessments() async {
    try {
      if (widget.serviceUserId != null) {
        return await _service.getAssessmentsByServiceUser(widget.serviceUserId!);
      } else {
        return await _service.getAllAssessments();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assessments: $error')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshAssessments() async {
    setState(() {
      _assessmentsFuture = _loadAssessments();
    });
  }

  Future<void> _createAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DomiciliaryFireSafetyForm(),
      ),
    );
    if (result == true) _refreshAssessments();
  }

  Future<void> _editAssessment(DomiciliaryFireSafetyAssessment assessment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DomiciliaryFireSafetyForm(assessment: assessment),
      ),
    );
    if (result == true) _refreshAssessments();
  }

  Future<void> _deleteAssessment(String assessmentId) async {
    setState(() => _isLoading = true);
    try {
      await _service.deleteAssessment(assessmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment deleted')));
      }
      _refreshAssessments();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceUserId != null ? 'Fire Safety' : 'All Fire Safety'),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAssessment,
        backgroundColor: const Color(0xFFF44336),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<DomiciliaryFireSafetyAssessment>>(
              future: _assessmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No fire safety assessments found'));
                } else {
                  final assessments = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _refreshAssessments,
                    child: ListView.builder(
                      itemCount: assessments.length,
                      itemBuilder: (context, index) {
                        final a = assessments[index];
                        final riskColor = _getRiskColor(a.riskLevel);
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(a.assessorName ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${a.assessmentDate?.toString().split(' ').first ?? 'N/A'}'),
                                Text('Risk: ${a.riskLevel?.toUpperCase() ?? 'N/A'}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: riskColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (a.riskLevel ?? 'low').toUpperCase(),
                                    style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editAssessment(a)),
                                IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: a.id != null ? () => _deleteAssessment(a.id!) : null),
                              ],
                            ),
                            onTap: () => _editAssessment(a),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
    );
  }
}