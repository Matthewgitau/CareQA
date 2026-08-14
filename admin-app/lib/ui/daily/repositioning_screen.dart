import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/repositioning_service.dart';
import 'package:admin_app/models/repositioning_chart.dart';
import 'package:admin_app/ui/daily/repositioning_audit.dart';

class RepositioningScreen extends StatefulWidget {
  final String serviceUserId;
  final String? serviceUserName;

  const RepositioningScreen({
    Key? key,
    required this.serviceUserId,
    this.serviceUserName,
  }) : super(key: key);

  @override
  _RepositioningScreenState createState() => _RepositioningScreenState();
}

class _RepositioningScreenState extends State<RepositioningScreen> with SingleTickerProviderStateMixin {
  final _repositioningService = RepositioningService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  
  late TabController _tabController;
  List<RepositioningChartSummary> _chartSummaries = [];
  RepositioningChart? _currentChart;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCharts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    try {
      _chartSummaries = await _repositioningService.getChartSummariesForServiceUser(widget.serviceUserId);
      if (_chartSummaries.isNotEmpty) {
        _currentChart = await _repositioningService.getChart(_chartSummaries.first.id);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading charts: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectChart(String chartId) async {
    setState(() => _isLoading = true);
    try {
      _currentChart = await _repositioningService.getChart(chartId);
      _tabController.index = 1; // Switch to edit tab
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chart: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChart() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate entries
    for (int i = 0; i < _currentChart!.entries.length; i++) {
      final entry = _currentChart!.entries[i];
      if (entry.staffInitials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please provide staff initials for entry ${i + 1}')),
        );
        return;
      }
      if (entry.skinCheck == 'Yes-Concern' && (entry.skinCheckNotes?.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please provide skin check notes for entry ${i + 1} when concern is selected')),
        );
        return;
      }
    }

    try {
      final updates = {
        'entries': _currentChart!.entries.map((e) => e.toJson()).toList(),
        'total_repositions': _currentChart!.entries.length,
        'notes': _currentChart!.notes,
      };

      await _repositioningService.updateChart(_currentChart!.id!, updates, Supabase.instance.client.auth.currentUser!.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart updated successfully')),
      );
      
      _isEditing = false;
      _tabController.index = 0; // Switch back to list tab
      await _loadCharts();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating chart: $error')),
      );
    }
  }

  Future<void> _deleteChart() async {
    if (_currentChart == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chart'),
        content: const Text('Are you sure you want to delete this chart? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repositioningService.deleteChart(_currentChart!.id!, Supabase.instance.client.auth.currentUser!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chart deleted successfully')),
        );
        _currentChart = null;
        _isEditing = false;
        _tabController.index = 0;
        await _loadCharts();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting chart: $error')),
        );
      }
    }
  }

  void _addEntry() {
    setState(() {
      _currentChart = _currentChart!.copyWith(
        entries: [
          ..._currentChart!.entries,
          RepositioningEntry(
            time: DateTime.now(),
            positionCode: 'B',
            skinCheck: 'No',
            skinCheckNotes: '',
            staffInitials: '',
          ),
        ],
      );
    });
  }

  void _removeEntry(int index) {
    setState(() {
      final entries = List<RepositioningEntry>.from(_currentChart!.entries);
      entries.removeAt(index);
      _currentChart = _currentChart!.copyWith(entries: entries);
    });
  }

  void _updateEntry(int index, RepositioningEntry entry) {
    setState(() {
      final entries = List<RepositioningEntry>.from(_currentChart!.entries);
      entries[index] = entry;
      _currentChart = _currentChart!.copyWith(entries: entries);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentChart!.chartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _currentChart = _currentChart!.copyWith(chartDate: picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_currentChart!.entries[index].time),
    );
    if (picked != null) {
      setState(() {
        final entries = List<RepositioningEntry>.from(_currentChart!.entries);
        entries[index] = entries[index].copyWith(
          time: DateTime(
            _currentChart!.chartDate.year,
            _currentChart!.chartDate.month,
            _currentChart!.chartDate.day,
            picked.hour,
            picked.minute,
          ),
        );
        _currentChart = _currentChart!.copyWith(entries: entries);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Repositioning Charts - ${widget.serviceUserName ?? 'Service User'}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'View Charts'),
            Tab(text: 'Edit Chart'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: View Charts
                _buildViewTab(),
                // Tab 2: Edit Chart
                _buildEditTab(),
              ],
            ),
    );
  }

  Widget _buildViewTab() {
    if (_chartSummaries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No repositioning charts found', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Create a new chart to get started'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCharts,
      child: ListView.builder(
        itemCount: _chartSummaries.length,
        itemBuilder: (context, index) {
          final summary = _chartSummaries[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: summary.hasSkinConcerns
                  ? Icon(Icons.warning, color: Colors.red)
                  : Icon(Icons.check_circle, color: Colors.green),
              title: Text(
                '${summary.chartDate.day}/${summary.chartDate.month}/${summary.chartDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Repositions: ${summary.totalRepositions}'),
                  if (summary.hasSkinConcerns)
                    const Text('⚠️ Skin concerns detected', style: TextStyle(color: Colors.red)),
                  if (summary.createdBy != null)
                    Text('Created by: ${summary.createdBy}'),
                  if (summary.updatedBy != null && summary.updatedBy != summary.createdBy)
                    Text('Last edited by: ${summary.updatedBy}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectChart(summary.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditTab() {
    if (_currentChart == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.select_all, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a chart to edit', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Go to the View Charts tab and tap a chart'),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Chart header with metadata
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Chart Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentChart!.chartDate.day}/${_currentChart!.chartDate.month}/${_currentChart!.chartDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_currentChart!.createdBy != null)
                    Text('Created by: ${_currentChart!.createdBy}'),
                  if (_currentChart!.createdAt != null)
                    Text('Created: ${_currentChart!.createdAt!.toLocal().formatDate()}'),
                  if (_currentChart!.updatedBy != null && _currentChart!.updatedBy != _currentChart!.createdBy)
                    Text('Last edited by: ${_currentChart!.updatedBy}'),
                  if (_currentChart!.updatedAt != null && _currentChart!.updatedAt != _currentChart!.createdAt)
                    Text('Last edited: ${_currentChart!.updatedAt!.toLocal().formatDate()}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Position codes reference
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Position Codes Reference',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildPositionCodeRow('L', 'Left side'),
                  _buildPositionCodeRow('R', 'Right side'),
                  _buildPositionCodeRow('B', 'Back (supine)'),
                  _buildPositionCodeRow('S', 'Sitting'),
                  _buildPositionCodeRow('S30', '30° tilt left'),
                  _buildPositionCodeRow('S30R', '30° tilt right'),
                  _buildPositionCodeRow('U', 'Up in chair'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Entries
          const Text(
            'Repositioning Entries',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),

          if (_currentChart!.entries.isEmpty)
            const Text('No entries added yet.'),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentChart!.entries.length,
            itemBuilder: (context, index) {
              final entry = _currentChart!.entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Entry ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeEntry(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Time picker
                      Row(
                        children: [
                          const Text('Time:'),
                          const SizedBox(width: 16),
                          Text(
                            '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context, index),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Position code
                      DropdownButtonFormField<String>(
                        value: entry.positionCode,
                        decoration: const InputDecoration(
                          labelText: 'Position Code',
                        ),
                        items: RepositioningConstants.positionOptions.map((code) {
                          return DropdownMenuItem(
                            value: code,
                            child: Text('$code - ${RepositioningConstants.positionCodes[code]}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _updateEntry(index, entry.copyWith(positionCode: value!));
                        },
                      ),

                      const SizedBox(height: 8),

                      // Skin check
                      DropdownButtonFormField<String>(
                        value: entry.skinCheck,
                        decoration: const InputDecoration(
                          labelText: 'Skin Check',
                        ),
                        items: RepositioningConstants.skinCheckOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Row(
                              children: [
                                Icon(
                                  option == 'Yes-NAD' ? Icons.check_circle : 
                                  option == 'Yes-Concern' ? Icons.warning : Icons.remove_circle,
                                  color: option == 'Yes-NAD' ? Colors.green :
                                         option == 'Yes-Concern' ? Colors.red : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(option),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _updateEntry(index, entry.copyWith(skinCheck: value!));
                        },
                      ),

                      const SizedBox(height: 8),

                      // Skin check notes (only if concern)
                      if (entry.skinCheck == 'Yes-Concern')
                        TextFormField(
                          initialValue: entry.skinCheckNotes,
                          decoration: const InputDecoration(
                            labelText: 'Skin Check Notes',
                            hintText: 'Describe the concern...',
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            _updateEntry(index, entry.copyWith(skinCheckNotes: value));
                          },
                        ),

                      const SizedBox(height: 8),

                      // Staff initials
                      TextFormField(
                        initialValue: entry.staffInitials,
                        decoration: const InputDecoration(
                          labelText: 'Staff Initials',
                        ),
                        onChanged: (value) {
                          _updateEntry(index, entry.copyWith(staffInitials: value));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Add entry button
          ElevatedButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.add),
            label: const Text('Add Entry'),
          ),

          const SizedBox(height: 16),

          // Total repositions
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Total Repositions:'),
                  const SizedBox(width: 16),
                  Text(
                    _currentChart!.entries.length.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  if (_currentChart!.hasSkinConcerns())
                    const Text('⚠️ Skin concerns detected', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes
          TextFormField(
            initialValue: _currentChart!.notes,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Additional observations...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (value) {
              _currentChart = _currentChart!.copyWith(notes: value);
            },
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChart,
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.index = 0;
                    _isEditing = false;
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RepositioningAuditScreen(chartId: _currentChart!.id!),
                    ),
                  ),
                  child: const Text('View Audit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleteChart,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCodeRow(String code, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(description),
        ],
      ),
    );
  }
}

// Extension for date formatting
extension DateTimeExtensions on DateTime {
  String formatDate() {
    return '${day}/${month}/${year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// Extension to make RepositioningChart mutable
extension RepositioningChartExtensions on RepositioningChart {
  RepositioningChart copyWith({
    DateTime? chartDate,
    List<RepositioningEntry>? entries,
    int? totalRepositions,
    String? notes,
  }) {
    return RepositioningChart(
      id: id,
      serviceUserId: serviceUserId,
      chartDate: chartDate ?? this.chartDate,
      entries: entries ?? this.entries,
      totalRepositions: totalRepositions ?? this.totalRepositions,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
    );
  }
}

// Extension to make RepositioningEntry mutable
extension RepositioningEntryExtensions on RepositioningEntry {
  RepositioningEntry copyWith({
    DateTime? time,
    String? positionCode,
    String? skinCheck,
    String? skinCheckNotes,
    String? staffInitials,
  }) {
    return RepositioningEntry(
      time: time ?? this.time,
      positionCode: positionCode ?? this.positionCode,
      skinCheck: skinCheck ?? this.skinCheck,
      skinCheckNotes: skinCheckNotes ?? this.skinCheckNotes,
      staffInitials: staffInitials ?? this.staffInitials,
    );
  }
}