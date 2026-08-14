import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';

/// Screen displaying a list of competency assessments.
/// Can be filtered by competency category or status.
class CompetencyListScreen extends StatefulWidget {
  final String? competencyType;
  final String competencyName;
  final String? filterStatus;

  const CompetencyListScreen({
    super.key,
    this.competencyType,
    required this.competencyName,
    this.filterStatus,
  });

  @override
  State<CompetencyListScreen> createState() => _CompetencyListScreenState();
}

class _CompetencyListScreenState extends State<CompetencyListScreen> {
  final _competencyService = CompetencyService(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _recordsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadRecords();
  }

  Future<List<Map<String, dynamic>>> _loadRecords() async {
    try {
      if (widget.filterStatus == 'expired') {
        return await _competencyService.getExpiredCompetencies();
      } else if (widget.filterStatus == 'expiring') {
        return await _competencyService.getExpiringCompetencies(30);
      } else if (widget.competencyType != null) {
        return await _competencyService.getRecordsByType(widget.competencyType!);
      } else {
        return await _competencyService.getAllRecords();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load records: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshRecords() async {
    setState(() {
      _recordsFuture = _loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.competencyName),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshRecords,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No competency records found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Records will appear here once staff complete their assessments',
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshRecords,
            child: ListView.builder(
              itemCount: records.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assessment,
                        color: Color(0xFF1565C0),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      record['staff']['full_name'] ?? 'Unknown Staff',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Assessment Type: ${record['assessment_type'] ?? 'N/A'}'),
                        const SizedBox(height: 2),
                        Text(
                          'Date: ${record['assessment_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(record['assessment_date'])) : 'N/A'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        if (record['expiry_date'] != null)
                          Text(
                            'Expires: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(record['expiry_date']))}',
                            style: TextStyle(
                              color: DateTime.parse(record['expiry_date']).isBefore(DateTime.now())
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: DateTime.parse(record['expiry_date']).isBefore(DateTime.now())
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(record['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(record['status']).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _getStatusDisplay(record['status']),
                            style: TextStyle(
                              color: _getStatusColor(record['status']),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _showRecordDetails(record),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assessment, color: Color(0xFF1565C0)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Assessment Details'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Staff Member',
                record['staff']['full_name'] ?? 'Unknown',
              ),
              _buildDetailRow(
                'Assessment Type',
                record['assessment_type'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Assessment Date',
                record['assessment_date'] != null 
                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(record['assessment_date']))
                    : 'N/A',
              ),
              if (record['expiry_date'] != null)
                _buildDetailRow(
                  'Expiry Date',
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(record['expiry_date'])),
                ),
              const Divider(),
              _buildStatusRow('Status', record['status'] ?? 'pending', _getStatusColor(record['status'])),
              _buildStatusRow('Overall Rating', record['overall_rating'] ?? 'N/A', _getRatingColor(record['overall_rating'])),
              if (record['assessor_name'] != null)
                _buildDetailRow('Assessor', record['assessor_name']),
              if (record['action_plan'] != null && record['action_plan'].isNotEmpty)
                _buildDetailRow('Action Plan', record['action_plan']),
              if (record['assessor_notes'] != null && record['assessor_notes'].isNotEmpty)
                _buildDetailRow('Notes', record['assessor_notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'requires_reassessment':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'requires_reassessment':
        return 'Needs Reassessment';
      case 'pending':
        return 'Pending';
      default:
        return status ?? 'Unknown';
    }
  }

  Color _getRatingColor(String? rating) {
    switch (rating?.toLowerCase()) {
      case 'competent':
        return Colors.green;
      case 'development_needed':
        return Colors.orange;
      case 'not_competent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}