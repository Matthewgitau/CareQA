import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/disciplinary_case.dart';
import '../../services/disciplinary_service.dart';
import 'disciplinary_form.dart';

class DisciplinaryScreen extends StatefulWidget {
  const DisciplinaryScreen({super.key});

  @override
  State<DisciplinaryScreen> createState() => _DisciplinaryScreenState();
}

class _DisciplinaryScreenState extends State<DisciplinaryScreen> {
  final _service = DisciplinaryService(Supabase.instance.client);
  List<DisciplinaryCase> _cases = [];
  List<DisciplinaryCase> _filteredCases = [];
  bool _isLoading = true;
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCases();
    _searchController.addListener(_filterCases);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      final cases = await _service.getAllCases();
      if (mounted) {
        setState(() {
          _cases = cases;
          _filteredCases = cases;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cases: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCases() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCases = _cases.where((case_) {
        final matchesSearch = query.isEmpty ||
            case_.staffName.toLowerCase().contains(query) ||
            (case_.caseReference ?? '').toLowerCase().contains(query);
        final matchesStatus = _selectedStatus == null || case_.status == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disciplinary Cases'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by staff name or case reference...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Open', 'open'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Investigating', 'investigating'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Hearing Scheduled', 'hearing_scheduled'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Decision Pending', 'decision_pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Closed', 'closed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Appealed', 'appealed'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredCases.isEmpty
              ? const Center(child: Text('No disciplinary cases found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredCases.length,
                  itemBuilder: (context, index) {
                    final case_ = _filteredCases[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          case_.caseReference ?? 'No Reference',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Staff: ${case_.staffName}'),
                            Text('Incident: ${DateFormat('dd/MM/yyyy').format(case_.incidentDate)}'),
                            Text('Type: ${case_.getIncidentTypeDisplay()}'),
                            Text('Status: ${case_.getStatusDisplay()}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: case_.getSeverityColor(),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                case_.getSeverityDisplay(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            if (case_.isConfidential)
                              const Icon(Icons.lock, size: 16, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _viewCase(case_),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCase,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
        _filterCases();
      },
    );
  }

  void _viewCase(DisciplinaryCase case_) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(case_.caseReference ?? 'Disciplinary Case'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Staff', case_.staffName),
              _buildDetailRow('Incident Date', DateFormat('dd/MM/yyyy').format(case_.incidentDate)),
              _buildDetailRow('Type', case_.getIncidentTypeDisplay()),
              _buildDetailRow('Severity', case_.getSeverityDisplay()),
              _buildDetailRow('Status', case_.getStatusDisplay()),
              if (case_.outcomeType != null)
                _buildDetailRow('Outcome', case_.getOutcomeTypeDisplay()),
              const SizedBox(height: 8),
              const Divider(),
              Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(case_.description),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editCase(case_);
            },
            child: const Text('Edit'),
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
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addCase() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DisciplinaryFormScreen()),
    );
    if (result == true) {
      _loadCases();
    }
  }

  void _editCase(DisciplinaryCase case_) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DisciplinaryFormScreen(case_: case_)),
    );
    if (result == true) {
      _loadCases();
    }
  }
}