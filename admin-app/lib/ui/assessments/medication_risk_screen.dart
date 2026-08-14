import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/ui/assessments/medication_risk_form.dart';

class MedicationRiskScreen extends StatefulWidget {
  const MedicationRiskScreen({super.key});
  @override
  State<MedicationRiskScreen> createState() => _MedicationRiskScreenState();
}

class _MedicationRiskScreenState extends State<MedicationRiskScreen> {
  List<Map<String, dynamic>> _assessments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('medication_risk_assessments')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _assessments = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showServiceUserPicker() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .eq('is_active', true)
          .order('name');

      final users = List<Map<String, dynamic>>.from(response as List);

      if (!mounted) return;

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Service User'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: users.isEmpty
                ? const Center(child: Text('No service users found'))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user['name']?.toString() ?? 'Unknown'),
                        onTap: () => Navigator.pop(context, user),
                      );
                    },
                  ),
          ),
        ),
      );

      if (result != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicationRiskForm(
              assessmentId: null,
            ),
          ),
        ).then((_) => _load());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading service users: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Risk Assessments'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showServiceUserPicker,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _assessments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No medication risk assessments found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _assessments.length,
                      itemBuilder: (_, i) {
                        final a = _assessments[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRiskColor(a['risk_level']),
                              child: const Icon(Icons.medication, color: Colors.white),
                            ),
                            title: Text(a['service_user_name'] ?? 'Unknown'),
                            subtitle: Text(
                              'Risk: ${a['risk_level'] ?? 'N/A'} — ${(a['assessment_date'] ?? '').toString().split('T').first}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
    );
  }

  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
