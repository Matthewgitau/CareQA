import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/bowel_bladder_chart.dart';
import '../../services/bowel_bladder_service.dart';
import '../../services/auth_service.dart';

class BowelBladderScreen extends StatefulWidget {
  final String serviceUserId;

  const BowelBladderScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _BowelBladderScreenState createState() => _BowelBladderScreenState();
}

class _BowelBladderScreenState extends State<BowelBladderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BowelBladderService _bowelBladderService;
  late AuthService _authService;
  List<BowelBladderChart> _charts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bowelBladderService = BowelBladderService(Supabase.instance.client);
    _authService = AuthService();
    _loadCharts();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    try {
      _charts = await _bowelBladderService.getForServiceUser(widget.serviceUserId);
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
        title: const Text('Bowel & Bladder Chart'),
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
    return NewBowelBladderChart(
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
                  builder: (context) => BowelBladderDetailScreen(chart: chart),
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

class NewBowelBladderChart extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onChartCreated;

  const NewBowelBladderChart({
    Key? key,
    required this.serviceUserId,
    required this.onChartCreated,
  }) : super(key: key);

  @override
  _NewBowelBladderChartState createState() => _NewBowelBladderChartState();
}

class _NewBowelBladderChartState extends State<NewBowelBladderChart> {
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
      'bowel': {
        'bristol_scale': '',
        'frequency': '',
        'consistency': '',
        'colour': '',
        'days_since_last': '',
      },
      'bladder': {
        'frequency': '',
        'urine_colour': '',
        'incontinence': false,
        'catheter': false,
      },
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
              'New Bowel & Bladder Chart',
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
              'Bowel Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildBowelSection(),
            const SizedBox(height: 24),
            Text(
              'Bladder Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildBladderSection(),
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

  Widget _buildBowelSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bristol Stool Scale',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _responses['bowel']!['bristol_scale'],
              decoration: const InputDecoration(labelText: 'Scale (1-7)'),
              items: [
                DropdownMenuItem(value: '1', child: Text('Type 1 - Separate hard lumps')),
                DropdownMenuItem(value: '2', child: Text('Type 2 - Sausage-shaped, lumpy')),
                DropdownMenuItem(value: '3', child: Text('Type 3 - Like a sausage with cracks')),
                DropdownMenuItem(value: '4', child: Text('Type 4 - Like a sausage, smooth')),
                DropdownMenuItem(value: '5', child: Text('Type 5 - Soft blobs with clear edges')),
                DropdownMenuItem(value: '6', child: Text('Type 6 - Fluffy pieces with ragged edges')),
                DropdownMenuItem(value: '7', child: Text('Type 7 - Watery, no solid pieces')),
              ],
              onChanged: (value) {
                _responses['bowel']!['bristol_scale'] = value;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Frequency'),
              onChanged: (value) {
                _responses['bowel']!['frequency'] = value;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Consistency'),
              onChanged: (value) {
                _responses['bowel']!['consistency'] = value;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Colour'),
              onChanged: (value) {
                _responses['bowel']!['colour'] = value;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Days since last bowel movement'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _responses['bowel']!['days_since_last'] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBladderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bladder Function',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Frequency'),
              onChanged: (value) {
                _responses['bladder']!['frequency'] = value;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _responses['bladder']!['urine_colour'],
              decoration: const InputDecoration(labelText: 'Urine Colour'),
              items: [
                DropdownMenuItem(value: 'clear', child: Text('Clear')),
                DropdownMenuItem(value: 'pale_yellow', child: Text('Pale Yellow')),
                DropdownMenuItem(value: 'yellow', child: Text('Yellow')),
                DropdownMenuItem(value: 'dark_yellow', child: Text('Dark Yellow')),
                DropdownMenuItem(value: 'amber', child: Text('Amber')),
                DropdownMenuItem(value: 'brown', child: Text('Brown')),
                DropdownMenuItem(value: 'red', child: Text('Red/Pink')),
                DropdownMenuItem(value: 'cloudy', child: Text('Cloudy')),
              ],
              onChanged: (value) {
                _responses['bladder']!['urine_colour'] = value;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _responses['bladder']!['incontinence'],
                  onChanged: (value) {
                    setState(() {
                      _responses['bladder']!['incontinence'] = value;
                    });
                  },
                ),
                const Text('Incontinence'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _responses['bladder']!['catheter'],
                  onChanged: (value) {
                    setState(() {
                      _responses['bladder']!['catheter'] = value;
                    });
                  },
                ),
                const Text('Catheter'),
              ],
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

      final chart = BowelBladderChart(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _bowelBladderService.create(chart);
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

class BowelBladderDetailScreen extends StatelessWidget {
  final BowelBladderChart chart;

  const BowelBladderDetailScreen({Key? key, required this.chart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bowel & Bladder Chart - ${DateFormat('dd/MM/yyyy').format(chart.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${chart.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildBowelDetails(),
            const SizedBox(height: 16),
            _buildBladderDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildBowelDetails() {
    final bowelData = chart.responses['bowel'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bowel Assessment',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Bristol Scale: ${bowelData['bristol_scale'] ?? ''}'),
            Text('Frequency: ${bowelData['frequency'] ?? ''}'),
            Text('Consistency: ${bowelData['consistency'] ?? ''}'),
            Text('Colour: ${bowelData['colour'] ?? ''}'),
            Text('Days since last: ${bowelData['days_since_last'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBladderDetails() {
    final bladderData = chart.responses['bladder'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bladder Assessment',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Frequency: ${bladderData['frequency'] ?? ''}'),
            Text('Urine Colour: ${bladderData['urine_colour'] ?? ''}'),
            Text('Incontinence: ${bladderData['incontinence'] ?? false ? 'Yes' : 'No'}'),
            Text('Catheter: ${bladderData['catheter'] ?? false ? 'Yes' : 'No'}'),
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
}