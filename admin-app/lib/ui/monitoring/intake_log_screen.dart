import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/food_fluid_intake_log.dart';
import 'package:admin_app/services/food_fluid_intake_service.dart';
import 'package:admin_app/ui/monitoring/intake_log_form.dart';

class IntakeLogScreen extends StatefulWidget {
  final String? serviceUserId;
  const IntakeLogScreen({super.key, this.serviceUserId});

  @override
  State<IntakeLogScreen> createState() => _IntakeLogScreenState();
}

class _IntakeLogScreenState extends State<IntakeLogScreen> {
  final _service = FoodFluidIntakeService(Supabase.instance.client);

  List<FoodFluidIntakeLog> _logs = [];
  List<Map<String, dynamic>> _serviceUsers = [];
  Map<String, String> _serviceUserNames = {};
  String? _selectedServiceUserId;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedServiceUserId = widget.serviceUserId;
    _loadServiceUsers();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      final users = List<Map<String, dynamic>>.from(data as List);
      _serviceUserNames = {
        for (final u in users) u['id'] as String: u['name'] as String,
      };
      setState(() => _serviceUsers = users);
    } catch (_) {}
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      _logs = await _service.getLogs(serviceUserId: _selectedServiceUserId, startDate: start, endDate: end);
    } catch (_) {
      _logs = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  List<FoodFluidIntakeLog> get _fluidLogs => _logs.where((l) => l.logType == 'fluid').toList();
  List<FoodFluidIntakeLog> get _foodLogs => _logs.where((l) => l.logType == 'food').toList();

  IconData _fluidIconFor(String? type) {
    switch (type) {
      case 'juice': return Icons.local_drink;
      case 'hot_drink': return Icons.coffee;
      case 'other': return Icons.science;
      default: return Icons.water_drop;
    }
  }

  IconData _mealIconFor(String? type) {
    switch (type) {
      case 'breakfast': return Icons.bakery_dining;
      case 'lunch': return Icons.lunch_dining;
      case 'dinner': return Icons.dinner_dining;
      case 'snack': return Icons.apple;
      default: return Icons.restaurant;
    }
  }

  int get _totalFluid => _fluidLogs.fold(0, (sum, l) => sum + (l.totalFluidMl ?? 0));
  int get _foodCount => _foodLogs.length;
  double get _avgFoodEaten {
    if (_foodLogs.isEmpty) return 0;
    final observed = _foodLogs.where((l) => l.foodObserved == true).toList();
    if (observed.isEmpty) return 0;
    final total = observed.fold(0, (sum, l) => sum + (l.foodEatenPercent ?? 0));
    return total / observed.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food & Fluid Intake Log'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => IntakeLogForm(
            serviceUserId: _selectedServiceUserId,
            initialDate: _selectedDate,
          ))).then((_) => _loadLogs());
        },
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<String?>(
                  value: _selectedServiceUserId,
                  decoration: InputDecoration(
                    labelText: 'Service User',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Service Users')),
                    ..._serviceUsers.map((u) => DropdownMenuItem(
                      value: u['id'] as String,
                      child: Text(u['name'] as String),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedServiceUserId = v);
                    _loadLogs();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context, initialDate: _selectedDate,
                            firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadLogs();
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                            isDense: true,
                          ),
                          child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() => _selectedDate = DateTime.now());
                        _loadLogs();
                      },
                      icon: const Icon(Icons.today),
                      tooltip: 'Today',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Summary card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('${_totalFluid}ml', 'Fluid'),
                _buildSummaryItem('$_foodCount/$_foodCount', 'Meals'),
                _buildSummaryItem('${_avgFoodEaten.toStringAsFixed(0)}%', 'Avg food'),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('Fluid Logs', 0, Icons.water_drop, const Color(0xFF1565C0)),
                _buildTab('Food Logs', 1, Icons.restaurant, Colors.green),
                _buildTab('Summary', 2, Icons.analytics, Colors.purple),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: _buildTabContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTab(String label, int index, IconData icon, Color color) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: isSelected ? color : Colors.transparent, width: 3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildFluidList();
      case 1:
        return _buildFoodList();
      case 2:
        return _buildSummaryList();
      default:
        return Container();
    }
  }

  Widget _buildFluidList() {
    if (_fluidLogs.isEmpty) {
      return const Center(child: Text('No fluid logs for this date'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _fluidLogs.length,
      itemBuilder: (_, i) => _buildLogCard(_fluidLogs[i], isFluid: true),
    );
  }

  Widget _buildFoodList() {
    if (_foodLogs.isEmpty) {
      return const Center(child: Text('No food logs for this date'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _foodLogs.length,
      itemBuilder: (_, i) => _buildLogCard(_foodLogs[i], isFluid: false),
    );
  }

  Widget _buildSummaryList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fluid:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_totalFluid}ml', style: const TextStyle(fontSize: 18, color: Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Meals Logged:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_foodCount', style: const TextStyle(fontSize: 18, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Average eaten:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_avgFoodEaten.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
        ),
        ..._logs.map((l) => _buildLogCard(l, isFluid: l.logType == 'fluid')),
      ],
    );
  }

  Widget _buildLogCard(FoodFluidIntakeLog log, {required bool isFluid}) {
    final color = isFluid ? const Color(0xFF1565C0) : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isFluid
                ? _fluidIconFor(log.fluidType)
                : _mealIconFor(log.mealType),
            color: color,
          ),
        ),
        title: Text(
          isFluid
              ? '${FoodFluidIntakeLog.fluidLabel(log.fluidType)} - ${log.totalFluidMl ?? 0}ml'
              : '${FoodFluidIntakeLog.mealLabel(log.mealType)} - ${log.foodObserved == true ? "${log.foodEatenPercent ?? 0}% eaten" : "Not observed"}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          '${log.logTime.hour.toString().padLeft(2, '0')}:${log.logTime.minute.toString().padLeft(2, '0')}'
          '${isFluid ? " • ${log.numberOfServings ?? 0}x${log.amountPerServingMl ?? 0}ml" : ""}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => IntakeLogForm(log: log))).then((_) => _loadLogs());
            } else if (v == 'delete') {
              await _service.deleteLog(log.id!);
              _loadLogs();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}