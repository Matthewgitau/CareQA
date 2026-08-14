import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/ui/risk/waterlow_form.dart';

class WaterlowScreen extends StatefulWidget {
  final String? serviceUserId;
  const WaterlowScreen({super.key, this.serviceUserId});

  @override
  State<WaterlowScreen> createState() => _WaterlowScreenState();
}

class _WaterlowScreenState extends State<WaterlowScreen> {
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
      PostgrestList data;
      if (widget.serviceUserId != null) {
        data = await Supabase.instance.client
            .from('waterlow_assessments')
            .select()
            .eq('service_user_id', widget.serviceUserId!)
            .order('assessment_date', ascending: false)
            .limit(50);
      } else {
        data = await Supabase.instance.client
            .from('waterlow_assessments')
            .select()
            .order('assessment_date', ascending: false)
            .limit(50);
      }
      setState(() {
        _assessments = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Color _getRiskColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 20) return Colors.red;
    if (score >= 15) return Colors.orange;
    if (score >= 10) return Colors.amber;
    return Colors.green;
  }

  String _getRiskLevel(int? score) {
    if (score == null) return 'Not scored';
    if (score >= 20) return 'Very High Risk';
    if (score >= 15) return 'High Risk';
    if (score >= 10) return 'At Risk';
    return 'No Risk';
  }

  void _openForm({String? assessmentId, String? serviceUserId, String? serviceUserName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaterlowForm(
          assessmentId: assessmentId,
          serviceUserId: serviceUserId ?? widget.serviceUserId,
          serviceUserName: serviceUserName,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waterlow Assessments'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.serviceUserId != null) {
            // If we already have a service user, open form directly
            _openForm(serviceUserId: widget.serviceUserId);
          } else {
            // Show service user picker first
            _showServiceUserPicker();
          }
        },
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
                          Icon(Icons.assessment, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No Waterlow assessments found',
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
                        final score = a['total_score'] as int?;
                        final riskColor = _getRiskColor(score);
                        final riskLevel = _getRiskLevel(score);
                        final date = a['assessment_date'] != null
                            ? (a['assessment_date'] as String).split('T').first
                            : 'No date';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: riskColor,
                              child: Text(
                                score?.toString() ?? '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              a['service_user_name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Risk: $riskLevel'),
                                Text('Date: $date'),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openForm(
                              assessmentId: a['id'] as String?,
                              serviceUserId: a['service_user_id'] as String?,
                              serviceUserName: a['service_user_name'] as String?,
                            ),
                          ),
                        );
                      },
                    ),
    );
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

      showDialog(
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
                        onTap: () {
                          Navigator.pop(context);
                          _openForm(
                            serviceUserId: user['id'] as String,
                            serviceUserName: user['name'] as String,
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading service users: $e')),
      );
    }
  }
}
