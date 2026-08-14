import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appraisal.dart';
import '../../services/appraisal_service.dart';
import 'appraisal_form.dart';
import 'appraisal_detail.dart';

/// Main screen showing list of all staff appraisals
class AppraisalsScreen extends StatefulWidget {
  const AppraisalsScreen({super.key});

  @override
  State<AppraisalsScreen> createState() => _AppraisalsScreenState();
}

class _AppraisalsScreenState extends State<AppraisalsScreen> {
  final _service = AppraisalService(Supabase.instance.client);
  List<Appraisal> _appraisals = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAppraisals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppraisals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final appraisals = await _service.getAllAppraisals();
      if (mounted) {
        setState(() {
          _appraisals = appraisals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Appraisal> get _filteredAppraisals {
    if (_searchQuery.isEmpty) return _appraisals;
    final query = _searchQuery.toLowerCase();
    return _appraisals.where((a) {
      final name = (a.employeeName ?? '').toLowerCase();
      final reviewer = (a.reviewerName ?? '').toLowerCase();
      return name.contains(query) || reviewer.contains(query);
    }).toList();
  }

  Future<void> _createAppraisal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AppraisalForm()),
    );
    if (result == true) {
      _loadAppraisals();
    }
  }

  Future<void> _viewAppraisal(Appraisal appraisal) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AppraisalDetail(appraisal: appraisal)),
    );
    if (result == true) {
      _loadAppraisals();
    }
  }

  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Appraisals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createAppraisal,
            tooltip: 'New Appraisal',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppraisals,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by employee or reviewer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error loading appraisals', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadAppraisals,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredAppraisals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty ? 'No appraisals match your search' : 'No appraisals found',
                                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text('Tap + to create a new appraisal', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAppraisals,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _filteredAppraisals.length,
                              itemBuilder: (context, index) {
                                final appraisal = _filteredAppraisals[index];
                                return _buildAppraisalCard(appraisal);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAppraisal,
        tooltip: 'New Appraisal',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppraisalCard(Appraisal appraisal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewAppraisal(appraisal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                    child: Text(
                      (appraisal.employeeName ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appraisal.employeeName ?? 'Unknown Employee',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Reviewer: ${appraisal.reviewerName ?? 'Unknown'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appraisal.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appraisal.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(appraisal.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details row
              Row(
                children: [
                  // Date
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(appraisal.appraisalDate),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 16),

                  // Rating
                  if (appraisal.overallRating != null) ...[
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${appraisal.overallRating}/5',
                      style: TextStyle(
                        color: _getRatingColor(appraisal.overallRating),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Next appraisal
                  Icon(Icons.date_range, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    appraisal.nextAppraisalDate != null
                        ? 'Next: ${DateFormat('dd MMM yyyy').format(appraisal.nextAppraisalDate!)}'
                        : 'Next: Not set',
                    style: TextStyle(
                      color: _getNextAppraisalColor(appraisal),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNextAppraisalColor(Appraisal appraisal) {
    if (appraisal.isNextAppraisalOverdue) return Colors.red;
    if (appraisal.isNextAppraisalDueSoon) return Colors.orange;
    return Colors.grey.shade600;
  }
}