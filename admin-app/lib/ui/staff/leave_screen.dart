import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/leave_request.dart';
import '../../services/leave_service.dart';
import 'leave_request_form.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> with SingleTickerProviderStateMixin {
  final _service = LeaveService(Supabase.instance.client);
  late TabController _tabController;
  List<LeaveRequest> _leaveRequests = [];
  List<LeaveRequest> _filteredRequests = [];
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => _loadLeaveRequests());
    _loadLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _service.getLeaveRequests();
      if (mounted) {
        setState(() {
          _leaveRequests = requests;
          _filteredRequests = requests;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leave requests: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterRequests(String? status) {
    setState(() {
      _selectedStatus = status;
      if (status == null) {
        _filteredRequests = _leaveRequests;
      } else {
        _filteredRequests = _leaveRequests.where((r) => r.status == status).toList();
      }
    });
  }

  Future<void> _approveLeave(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _service.approveLeave(id, user.id);
        _loadLeaveRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave approved'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectLeave(String id) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      try {
        await _service.rejectLeave(id, reason);
        _loadLeaveRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave rejected'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave & Pay'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Leave Requests', icon: Icon(Icons.event_note)),
            Tab(text: 'Payroll', icon: Icon(Icons.payments)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveTab(),
                _buildPayrollTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addLeaveRequest,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildLeaveTab() {
    return Column(
      children: [
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildFilterChip('All', null),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', 'approved'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
              const SizedBox(width: 8),
              _buildFilterChip('Cancelled', 'cancelled'),
            ],
          ),
        ),
        Expanded(
          child: _filteredRequests.isEmpty
              ? const Center(child: Text('No leave requests found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = _filteredRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(request.staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request.getLeaveTypeDisplay()),
                            Text('${DateFormat('dd/MM/yyyy').format(request.startDate)} - ${DateFormat('dd/MM/yyyy').format(request.endDate)}'),
                            Text('${request.totalDays.toStringAsFixed(1)} days'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(request.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                request.getStatusDisplay(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            if (request.status == 'pending') ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _approveLeave(request.id),
                                    child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _rejectLeave(request.id),
                                    child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        onTap: () => _viewLeaveDetails(request),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPayrollTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Payroll Processing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Payroll functionality coming soon', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _filterRequests(isSelected ? null : status),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      case 'withdrawn': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  void _viewLeaveDetails(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${request.getLeaveTypeDisplay()} - ${request.getStatusDisplay()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Staff', request.staffName),
              _buildDetailRow('Type', request.getLeaveTypeDisplay()),
              _buildDetailRow('Start', DateFormat('dd/MM/yyyy').format(request.startDate)),
              _buildDetailRow('End', DateFormat('dd/MM/yyyy').format(request.endDate)),
              _buildDetailRow('Days', '${request.totalDays.toStringAsFixed(1)}'),
              _buildDetailRow('Pay Rate', request.payRateType),
              _buildDetailRow('Pay %', '${request.payPercentage}%'),
              if (request.notes != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Notes:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(request.notes!),
              ],
              if (request.rejectedReason != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Rejection Reason:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text(request.rejectedReason!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (request.status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _approveLeave(request.id);
              },
              child: const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectLeave(request.id);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
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

  void _addLeaveRequest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveRequestFormScreen()),
    );
    if (result == true) {
      _loadLeaveRequests();
    }
  }
}