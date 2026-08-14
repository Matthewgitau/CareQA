import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/sleep_chart.dart';
import '../../services/sleep_service.dart';
import '../../services/auth_service.dart';

class SleepScreen extends StatefulWidget {
  final String serviceUserId;

  const SleepScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _SleepScreenState createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SleepService _sleepService;
  late AuthService _authService;
  List<SleepChart> _charts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sleepService = SleepService(Supabase.instance.client);
    _authService = AuthService();
    _loadCharts();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    try {
      _charts = await _sleepService.getForServiceUser(widget.serviceUserId);
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
        title: const Text('Sleep Chart'),
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
    return NewSleepChart(
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
                  builder: (context) => SleepDetailScreen(chart: chart),
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

class NewSleepChart extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onChartCreated;

  const NewSleepChart({
    Key? key,
    required this.serviceUserId,
    required this.onChartCreated,
  }) : super(key: key);

  @override
  _NewSleepChartState createState() => _NewSleepChartState();
}

class _NewSleepChartState extends State<NewSleepChart> {
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
      'bedtime_routine': '',
      'overnight_observations': [],
      'sleep_quality': '',
      'morning_summary': '',
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
              'New Sleep Chart',
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
              'Bedtime Routine',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildBedtimeRoutineSection(),
            const SizedBox(height: 24),
            Text(
              'Overnight Observations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildOvernightObservationsSection(),
            const SizedBox(height: 24),
            Text(
              'Sleep Quality & Morning Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildSleepQualitySection(),
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

  Widget _buildBedtimeRoutineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bedtime Routine Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Bedtime Routine'),
              initialValue: _responses['bedtime_routine'] ?? '',
              maxLines: 3,
              onChanged: (value) {
                _responses['bedtime_routine'] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOvernightObservationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overnight Observations',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildOvernightObservationsEntries(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addOvernightObservation,
              icon: const Icon(Icons.add),
              label: const Text('Add Observation'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOvernightObservationsEntries() {
    final entries = _responses['overnight_observations'] as List;
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
                        _responses['overnight_observations'][index]['time'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: data['observation_type'],
                      decoration: const InputDecoration(labelText: 'Observation Type'),
                      items: [
                        DropdownMenuItem(value: 'awake', child: Text('Awake')),
                        DropdownMenuItem(value: 'disturbed', child: Text('Disturbed')),
                        DropdownMenuItem(value: 'up_to_toilet', child: Text('Up to Toilet')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        _responses['overnight_observations'][index]['observation_type'] = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Details'),
                initialValue: data['details'] ?? '',
                maxLines: 2,
                onChanged: (value) {
                  _responses['overnight_observations'][index]['details'] = value;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _removeOvernightObservation(index),
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

  void _addOvernightObservation() {
    setState(() {
      _responses['overnight_observations'].add({
        'time': '',
        'observation_type': '',
        'details': '',
      });
    });
  }

  void _removeOvernightObservation(int index) {
    setState(() {
      _responses['overnight_observations'].removeAt(index);
    });
  }

  Widget _buildSleepQualitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep Quality Rating',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _responses['sleep_quality'],
              decoration: const InputDecoration(labelText: 'Sleep Quality'),
              items: [
                DropdownMenuItem(value: 'excellent', child: Text('Excellent')),
                DropdownMenuItem(value: 'good', child: Text('Good')),
                DropdownMenuItem(value: 'fair', child: Text('Fair')),
                DropdownMenuItem(value: 'poor', child: Text('Poor')),
                DropdownMenuItem(value: 'very_poor', child: Text('Very Poor')),
              ],
              onChanged: (value) {
                _responses['sleep_quality'] = value;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Morning Summary',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Morning Summary'),
              initialValue: _responses['morning_summary'] ?? '',
              maxLines: 3,
              onChanged: (value) {
                _responses['morning_summary'] = value;
              },
            ),
          ],
        ),
      ),
    );
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

      final chart = SleepChart(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _sleepService.create(chart);
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

class SleepDetailScreen extends StatelessWidget {
  final SleepChart chart;

  const SleepDetailScreen({Key? key, required this.chart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sleep Chart - ${DateFormat('dd/MM/yyyy').format(chart.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${chart.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildBedtimeRoutineDetails(),
            const SizedBox(height: 16),
            _buildOvernightObservationsDetails(),
            const SizedBox(height: 16),
            _buildSleepQualityDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildBedtimeRoutineDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bedtime Routine',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(_responses['bedtime_routine'] ?? 'No routine recorded'),
          ],
        ),
      ),
    );
  }

  Widget _buildOvernightObservationsDetails() {
    final observations = chart.responses['overnight_observations'] as List;
    if (observations.isEmpty) {
      return const Text('No overnight observations');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overnight Observations',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...observations.map((observation) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: ${observation['time'] ?? ''}'),
                    Text('Type: ${_getObservationTypeLabel(observation['observation_type'] ?? '')}'),
                    Text('Details: ${observation['details'] ?? ''}'),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepQualityDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep Quality & Morning Summary',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Sleep Quality: ${_getSleepQualityLabel(chart.responses['sleep_quality'] ?? '')}'),
            const SizedBox(height: 8),
            Text('Morning Summary: ${chart.responses['morning_summary'] ?? ''}'),
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

  String _getObservationTypeLabel(String type) {
    switch (type) {
      case 'awake': return 'Awake';
      case 'disturbed': return 'Disturbed';
      case 'up_to_toilet': return 'Up to Toilet';
      case 'other': return 'Other';
      default: return type;
    }
  }

  String _getSleepQualityLabel(String quality) {
    switch (quality) {
      case 'excellent': return 'Excellent';
      case 'good': return 'Good';
      case 'fair': return 'Fair';
      case 'poor': return 'Poor';
      case 'very_poor': return 'Very Poor';
      default: return quality;
    }
  }
}