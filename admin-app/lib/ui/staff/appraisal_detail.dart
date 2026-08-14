import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appraisal.dart';
import '../../services/appraisal_service.dart';
import 'appraisal_form.dart';

/// Read-only detail view of a single appraisal
class AppraisalDetail extends StatefulWidget {
  final Appraisal appraisal;

  const AppraisalDetail({super.key, required this.appraisal});

  @override
  State<AppraisalDetail> createState() => _AppraisalDetailState();
}

class _AppraisalDetailState extends State<AppraisalDetail> {
  final _service = AppraisalService(Supabase.instance.client);
  late Appraisal _appraisal;
  bool _isDeleting = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _appraisal = widget.appraisal;
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        setState(() {
          _isAdmin = profile['role'] == 'admin';
        });
      } catch (_) {}
    }
  }

  Future<void> _deleteAppraisal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appraisal'),
        content: const Text('Are you sure you want to delete this appraisal? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await _service.deleteAppraisal(_appraisal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appraisal deleted'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _editAppraisal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AppraisalForm(appraisal: _appraisal),
      ),
    );
    if (result == true && mounted) {
      final updated = await _service.getAppraisalById(_appraisal.id);
      if (updated != null && mounted) {
        setState(() => _appraisal = updated);
      }
    }
  }

  Color _getRatingIconColor() {
    if (_appraisal.overallRating == null) return Colors.grey;
    if (_appraisal.overallRating! >= 4) return Colors.green;
    if (_appraisal.overallRating! >= 3) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor() {
    switch (_appraisal.status) {
      case 'signed_off':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceRow(String label, String? value, {DateTime? date}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value),
                if (date != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appraisal Detail'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editAppraisal,
              tooltip: 'Edit',
            ),
          if (_isAdmin)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteAppraisal,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _appraisal.employeeName ?? 'Employee',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _getStatusColor()),
                          ),
                          child: Text(
                            _appraisal.statusDisplay,
                            style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Reviewed by: ${_appraisal.reviewerName ?? 'Unknown'}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(height: 16),

                    // Rating stars
                    if (_appraisal.overallRating != null)
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final filled = index < _appraisal.overallRating!;
                            return Icon(
                              filled ? Icons.star : Icons.star_border,
                              color: filled ? Colors.amber : Colors.grey.shade300,
                              size: 28,
                            );
                          }),
                          const SizedBox(width: 12),
                          Text(
                            '${_appraisal.overallRating}/5',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getRatingIconColor(),
                            ),
                          ),
                        ],
                      ),

                    const Divider(height: 24),

                    // Dates
                    _buildInfoRow(Icons.calendar_today, 'Appraisal Date',
                        DateFormat('dd MMMM yyyy').format(_appraisal.appraisalDate)),
                    const SizedBox(height: 8),
                    if (_appraisal.nextAppraisalDate != null)
                      _buildInfoRow(Icons.date_range, 'Next Appraisal Date',
                          DateFormat('dd MMMM yyyy').format(_appraisal.nextAppraisalDate!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detail sections
            _buildSection('Previous Goals Achieved', _appraisal.previousGoalsAchieved),
            _buildSection('Areas for Improvement', _appraisal.areasForImprovement),
            _buildSection('New Goals', _appraisal.newGoals),
            _buildSection('Comments', _appraisal.comments),

            // ---------- COMPLIANCE / SIGNATURE SECTION ----------
            if (_appraisal.employeeSignature != null ||
                _appraisal.reviewerSignature != null ||
                _appraisal.witnessName != null ||
                _appraisal.authorisedBy != null) ...[
              const Divider(height: 32, thickness: 1),
              const Text(
                'Compliance & Signatures',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildComplianceRow('Employee Signature', _appraisal.employeeSignature,
                  date: _appraisal.employeeSignatureDate),
              _buildComplianceRow('Reviewer Signature', _appraisal.reviewerSignature,
                  date: _appraisal.reviewerSignatureDate),
              _buildComplianceRow('Witness Name', _appraisal.witnessName),
              _buildComplianceRow('Witness Signature', _appraisal.witnessSignature),
              _buildComplianceRow('Authorised By', _appraisal.authorisedBy,
                  date: _appraisal.authorisedDate),
              if (_appraisal.completedDate != null)
                _buildComplianceRow('Completed Date',
                    DateFormat('dd MMMM yyyy').format(_appraisal.completedDate!)),
            ],

            // Footer with timestamps
            const Divider(),
            Text(
              'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(_appraisal.createdAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              'Last updated: ${DateFormat('dd/MM/yyyy HH:mm').format(_appraisal.updatedAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}