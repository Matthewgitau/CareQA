import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food_fluid_chart.dart';
import '../../services/food_fluid_service.dart';
import '../../services/auth_service.dart';

class FoodFluidScreen extends StatefulWidget {
  final String serviceUserId;

  const FoodFluidScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _FoodFluidScreenState createState() => _FoodFluidScreenState();
}

class _FoodFluidScreenState extends State<FoodFluidScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FoodFluidService _foodFluidService;
  late AuthService _authService;
  List<FoodFluidChart> _charts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _foodFluidService = FoodFluidService(Supabase.instance.client);
    _authService = AuthService();
    _loadCharts();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    try {
      _charts = await _foodFluidService.getForServiceUser(widget.serviceUserId);
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
        title: const Text('Food & Fluid Chart'),
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
    return NewFoodFluidChart(
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
                  builder: (context) => FoodFluidDetailScreen(chart: chart),
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

class NewFoodFluidChart extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onChartCreated;

  const NewFoodFluidChart({
    Key? key,
    required this.serviceUserId,
    required this.onChartCreated,
  }) : super(key: key);

  @override
  _NewFoodFluidChartState createState() => _NewFoodFluidChartState();
}

class _NewFoodFluidChartState extends State<NewFoodFluidChart> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  // Meal periods
  final List<String> _mealPeriods = [
    'breakfast', 'mid_morning', 'lunch', 'afternoon', 'evening', 'supper'
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _initializeResponses();
  }

  void _initializeResponses() {
    for (String period in _mealPeriods) {
      _responses[period] = {
        'time': '',
        'food_offered': '',
        'food_eaten': '',
        'fluid_type': '',
        'amount_ml': '',
      };
    }
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
              'New Food & Fluid Chart',
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
              'Meal Periods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildMealPeriods(),
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

  Widget _buildMealPeriods() {
    return Column(
      children: _mealPeriods.map((period) {
        final periodLabel = _getPeriodLabel(period);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Time'),
                        onChanged: (value) {
                          _responses[period]!['time'] = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Food Offered'),
                        onChanged: (value) {
                          _responses[period]!['food_offered'] = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _responses[period]!['food_eaten'],
                        decoration: const InputDecoration(labelText: 'Food Eaten'),
                        items: [
                          DropdownMenuItem(value: 'none', child: Text('None')),
                          DropdownMenuItem(value: 'quarter', child: Text('1/4')),
                          DropdownMenuItem(value: 'half', child: Text('1/2')),
                          DropdownMenuItem(value: 'three_quarters', child: Text('3/4')),
                          DropdownMenuItem(value: 'all', child: Text('All')),
                        ],
                        onChanged: (value) {
                          _responses[period]!['food_eaten'] = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Fluid Type'),
                        onChanged: (value) {
                          _responses[period]!['fluid_type'] = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Amount (ml)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _responses[period]!['amount_ml'] = value;
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'breakfast': return 'Breakfast';
      case 'mid_morning': return 'Mid Morning';
      case 'lunch': return 'Lunch';
      case 'afternoon': return 'Afternoon';
      case 'evening': return 'Evening';
      case 'supper': return 'Supper';
      default: return period;
    }
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

      final chart = FoodFluidChart(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _foodFluidService.create(chart);
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

class FoodFluidDetailScreen extends StatelessWidget {
  final FoodFluidChart chart;

  const FoodFluidDetailScreen({Key? key, required this.chart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food & Fluid Chart - ${DateFormat('dd/MM/yyyy').format(chart.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${chart.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildMealDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealDetails() {
    return Column(
      children: chart.responses.entries.map((entry) {
        final period = entry.key;
        final data = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPeriodLabel(period),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text('Time: ${data['time'] ?? ''}'),
                Text('Food Offered: ${data['food_offered'] ?? ''}'),
                Text('Food Eaten: ${data['food_eaten'] ?? ''}'),
                Text('Fluid Type: ${data['fluid_type'] ?? ''}'),
                Text('Amount: ${data['amount_ml'] ?? ''} ml'),
              ],
            ),
          ),
        );
      }).toList(),
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

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'breakfast': return 'Breakfast';
      case 'mid_morning': return 'Mid Morning';
      case 'lunch': return 'Lunch';
      case 'afternoon': return 'Afternoon';
      case 'evening': return 'Evening';
      case 'supper': return 'Supper';
      default: return period;
    }
  }
}