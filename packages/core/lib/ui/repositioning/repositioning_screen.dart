import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/repositioning_chart.dart';
import '../../services/repositioning_service.dart';
import '../../services/auth_service.dart';

class RepositioningScreen extends StatefulWidget {
  final String serviceUserId;

  const RepositioningScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _RepositioningScreenState createState() => _RepositioningScreenState();
}

class _RepositioningScreenState extends State<RepositioningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RepositioningService _repositioningService;
  late AuthService _authService;
  List<RepositioningChart> _charts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _repositioningService = RepositioningService(Supabase.instance.client);
    _authService = AuthService();
    _loadCharts();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    try {
      _charts = await _repositioningService.getForServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load charts: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repositioning Chart'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'History'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewChartTab(),
          _buildHistoryTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildNewChartTab() {
    return NewRepositioningChart(
      serviceUserId: widget.serviceUserId,
      onChartCreated: () {
        _loadCharts();
        _tabController.index = 1; // Switch to history tab
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_charts.isEmpty) {
      return const Center(child: Text('No charts found'));
    }

    return ListView.builder(
      itemCount: _charts.length,
      itemBuilder: (context, index) {
        final chart = _charts[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(chart.assessmentDate)),
            subtitle: Text('Status: ${chart.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RepositioningDetailScreen(chart: chart),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    return const Center(child: Text('Summary coming soon'));
  }
}

class NewRepositioningChart extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onChartCreated;

  const NewRepositioningChart({
    Key? key,
    required this.serviceUserId,
    required this.onChartCreated,
  }) : super(key: key);

  @override
  _NewRepositioningChartState createState() => _NewRepositioningChartState();
}

class _NewRepositioningChartState extends State<NewRepositioningChart> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'repositionings': [],
      'skin_checks': [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Repositioning Chart',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _dateController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Repositioning Records',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildRepositioningSection(),
            const SizedBox(height: 24),
            Text(
              'Skin Checks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildSkinCheckSection(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChart,
                    child: const Text('Save Chart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepositioningSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repositioning Entries',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildRepositioningEntries(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addRepositioningEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Repositioning'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRepositioningEntries() {
    final entries = _responses['repositionings'] as List;
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Time'),
                      initialValue: data['time'] ?? '',
                      onChanged: (value) {
                        _responses['repositionings'][index]['time'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: data['position'],
                      decoration: const InputDecoration(labelText: 'Position'),
                      items: [
                        DropdownMenuItem(value: 'L', child: Text('Left Side')),
                        DropdownMenuItem(value: 'R', child: Text('Right Side')),
                        DropdownMenuItem(value: 'B', child: Text('Back')),
                        DropdownMenuItem(value: 'S', child: Text('Sitting')),
                        DropdownMenuItem(value: 'S30', child: Text('30° Semi-Fowler')),
                        DropdownMenuItem(value: 'S30R', child: Text('30° Right Semi-Fowler')),
                        DropdownMenuItem(value: 'U', child: Text('Upright')),
                      ],
                      onChanged: (value) {
                        _responses['repositionings'][index]['position'] = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Staff Initials'),
                      initialValue: data['staff_initials'] ?? '',
                      onChanged: (value) {
                        _responses['repositionings'][index]['staff_initials'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Notes'),
                      initialValue: data['notes'] ?? '',
                      onChanged: (value) {
                        _responses['repositionings'][index]['notes'] = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _removeRepositioningEntry(index),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addRepositioningEntry() {
    setState(() {
      _responses['repositionings'].add({
        'time': '',
        'position': '',
        'staff_initials': '',
        'notes': '',
      });
    });
  }

  void _removeRepositioningEntry(int index) {
    setState(() {
      _responses['repositionings'].removeAt(index);
    });
  }

  Widget _buildSkinCheckSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skin Check Results',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildSkinCheckEntries(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addSkinCheckEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Skin Check'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSkinCheckEntries() {
    final entries = _responses['skin_checks'] as List;
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Time'),
                      initialValue: data['time'] ?? '',
                      onChanged: (value) {
                        _responses['skin_checks'][index]['time'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: data['result'],
                      decoration: const InputDecoration(labelText: 'Result'),
                      items: [
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'redness', child: Text('Redness')),
                        DropdownMenuItem(value: 'blanching', child: Text('Blanching')),
                        DropdownMenuItem(value: 'pressure_injury', child: Text('Pressure Injury')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        _responses['skin_checks'][index]['result'] = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location/Details'),
                initialValue: data['details'] ?? '',
                onChanged: (value) {
                  _responses['skin_checks'][index]['details'] = value;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _removeSkinCheckEntry(index),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addSkinCheckEntry() {
    setState(() {
      _responses['skin_checks'].add({
        'time': '',
        'result': '',
        'details': '',
      });
    });
  }

  void _removeSkinCheckEntry(int index) {
    setState(() {
      _responses['skin_checks'].removeAt(index);
    });
  }

  Future<void> _saveChart() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final chart = RepositioningChart(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _repositioningService.create(chart);
      widget.onChartCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save chart: $e')),
      );
    }
  }
}

class RepositioningDetailScreen extends StatelessWidget {
  final RepositioningChart chart;

  const RepositioningDetailScreen({Key? key, required this.chart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Repositioning Chart - ${DateFormat('dd/MM/yyyy').format(chart.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${chart.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildRepositioningDetails(),
            const SizedBox(height: 16),
            _buildSkinCheckDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildRepositioningDetails() {
    final repositionings = chart.responses['repositionings'] as List;
    if (repositionings.isEmpty) {
      return const Text('No repositioning entries');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repositioning Entries',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...repositionings.map((entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: ${entry['time'] ?? ''}'),
                    Text('Position: ${_getPositionLabel(entry['position'] ?? '')}'),
                    Text('Staff: ${entry['staff_initials'] ?? ''}'),
                    Text('Notes: ${entry['notes'] ?? ''}'),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinCheckDetails() {
    final skinChecks = chart.responses['skin_checks'] as List;
    if (skinChecks.isEmpty) {
      return const Text('No skin check entries');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skin Check Results',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...skinChecks.map((entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: ${entry['time'] ?? ''}'),
                    Text('Result: ${_getSkinResultLabel(entry['result'] ?? '')}'),
                    Text('Details: ${entry['details'] ?? ''}'),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPlan() {
    if (chart.actionPlan.isEmpty) {
      return const Text('No action plan items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Action Plan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...chart.actionPlan.map((item) => Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(item['description'] ?? ''),
          ),
        )),
      ],
    );
  }

  String _getPositionLabel(String position) {
    switch (position) {
      case 'L': return 'Left Side';
      case 'R': return 'Right Side';
      case 'B': return 'Back';
      case 'S': return 'Sitting';
      case 'S30': return '30° Semi-Fowler';
      case 'S30R': return '30° Right Semi-Fowler';
      case 'U': return 'Upright';
      default: return position;
    }
  }

  String _getSkinResultLabel(String result) {
    switch (result) {
      case 'normal': return 'Normal';
      case 'redness': return 'Redness';
      case 'blanching': return 'Blanching';
      case 'pressure_injury': return 'Pressure Injury';
      case 'other': return 'Other';
      default: return result;
    }
  }
}