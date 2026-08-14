import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/food_fluid_intake_log.dart';
import 'package:admin_app/services/food_fluid_intake_service.dart';

class IntakeLogForm extends StatefulWidget {
  final FoodFluidIntakeLog? log;
  final String? serviceUserId;
  final DateTime? initialDate;

  const IntakeLogForm({super.key, this.log, this.serviceUserId, this.initialDate});

  @override
  State<IntakeLogForm> createState() => _IntakeLogFormState();
}

class _IntakeLogFormState extends State<IntakeLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = FoodFluidIntakeService(Supabase.instance.client);

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  // Log type
  String _logType = 'fluid';

  // Common
  DateTime _logDate = DateTime.now();
  TimeOfDay _logTime = TimeOfDay.now();
  String _assessorName = '';
  final _notesController = TextEditingController();

  // Fluid fields
  String _fluidType = 'water';
  int _amountPerServing = 250;
  int _numberOfServings = 1;

  // Food fields
  String _mealType = 'breakfast';
  bool _foodObserved = true;
  String _platePercentage = 'all';
  final _foodDetailsController = TextEditingController();

  bool _isLoading = false;

  final List<int> _presetAmounts = [50, 100, 250, 500];
  final List<String> _fluidOptions = ['water', 'juice', 'hot_drink', 'other'];
  final List<String> _mealOptions = ['breakfast', 'lunch', 'dinner', 'snack'];
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

  final List<Map<String, String>> _plateOptions = [
    {'value': 'none', 'label': 'Empty plate', 'percent': '0%'},
    {'value': 'quarter', 'label': 'Quarter eaten', 'percent': '25%'},
    {'value': 'third', 'label': 'Third eaten', 'percent': '33%'},
    {'value': 'half', 'label': 'Half eaten', 'percent': '50%'},
    {'value': 'three_quarters', 'label': 'Three quarters eaten', 'percent': '75%'},
    {'value': 'all', 'label': 'All eaten', 'percent': '100%'},
  ];

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _initialize();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  void _initialize() {
    _assessorName = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Current User';

    if (widget.log != null) {
      final l = widget.log!;
      _selectedServiceUserId = l.serviceUserId;
      _logDate = l.logDate;
      _logTime = TimeOfDay.fromDateTime(l.logTime);
      _assessorName = l.assessorName.isNotEmpty ? l.assessorName : _assessorName;
      _notesController.text = l.notes ?? '';
      _logType = l.logType;
      if (l.logType == 'fluid') {
        _fluidType = l.fluidType ?? 'water';
        _amountPerServing = l.amountPerServingMl ?? 250;
        _numberOfServings = l.numberOfServings ?? 1;
      } else {
        _mealType = l.mealType ?? 'breakfast';
        _foodObserved = l.foodObserved ?? true;
        _platePercentage = l.platePercentage ?? 'all';
        _foodDetailsController.text = l.foodDetails ?? '';
      }
    } else if (widget.serviceUserId != null) {
      _selectedServiceUserId = widget.serviceUserId;
    }
    if (widget.initialDate != null) {
      _logDate = widget.initialDate!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _foodDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _logDate,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _logDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _logTime);
    if (picked != null) setState(() => _logTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service user')));
      return;
    }
    if (_logDate.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date cannot be in the future')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final serviceUserName = _serviceUsers
          .firstWhere((u) => u['id'] == _selectedServiceUserId)['name'] as String;

      DateTime logDateTime = DateTime(
        _logDate.year, _logDate.month, _logDate.day,
        _logTime.hour, _logTime.minute,
      );

      FoodFluidIntakeLog log;
      if (_logType == 'fluid') {
        final total = _amountPerServing * _numberOfServings;
        log = FoodFluidIntakeLog(
          id: widget.log?.id,
          serviceUserId: _selectedServiceUserId,
          serviceUserName: serviceUserName,
          logDate: _logDate,
          logTime: logDateTime,
          assessorName: _assessorName,
          logType: 'fluid',
          fluidType: _fluidType,
          amountPerServingMl: _amountPerServing,
          numberOfServings: _numberOfServings,
          totalFluidMl: total,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: widget.log?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        final eaten = FoodFluidIntakeLog.percentageFromPlate(_platePercentage);
        log = FoodFluidIntakeLog(
          id: widget.log?.id,
          serviceUserId: _selectedServiceUserId,
          serviceUserName: serviceUserName,
          logDate: _logDate,
          logTime: logDateTime,
          assessorName: _assessorName,
          logType: 'food',
          mealType: _mealType,
          foodObserved: _foodObserved,
          platePercentage: _platePercentage,
          foodEatenPercent: _foodObserved ? eaten : null,
          foodWastePercent: _foodObserved ? (100 - eaten) : null,
          foodDetails: _foodDetailsController.text.isNotEmpty ? _foodDetailsController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: widget.log?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      if (widget.log != null) {
        await _service.updateLog(widget.log!.id!, log);
      } else {
        await _service.createLog(log);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log saved successfully'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildCounter(String label, int value, ValueChanged<int> onChanged, {String? unit, int min = 0, int max = 9999, int step = 50}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value > min ? () => onChanged(value - step) : null,
                  icon: const Icon(Icons.remove_circle, size: 32, color: Colors.red),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$value${unit ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: value < max ? () => onChanged(value + step) : null,
                  icon: const Icon(Icons.add_circle, size: 32, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluidSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fluid Type', color: const Color(0xFF1565C0)),
        DropdownButtonFormField<String>(
          value: _fluidType,
          decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_drink)),
          items: _fluidOptions.map((t) => DropdownMenuItem(
            value: t,
            child: Row(children: [
              Icon(_fluidIconFor(t), size: 20),
              const SizedBox(width: 8),
              Text(FoodFluidIntakeLog.fluidLabel(t)),
            ]),
          )).toList(),
          onChanged: (v) => setState(() => _fluidType = v!),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Amount per serving'),
        Wrap(
          spacing: 8,
          children: _presetAmounts.map((amount) => ChoiceChip(
            label: Text('${amount}ml'),
            selected: _amountPerServing == amount,
            onSelected: (_) => setState(() => _amountPerServing = amount),
            selectedColor: const Color(0xFF1565C0).withOpacity(0.2),
            labelStyle: TextStyle(
              color: _amountPerServing == amount ? const Color(0xFF1565C0) : Colors.black,
              fontWeight: _amountPerServing == amount ? FontWeight.bold : FontWeight.normal,
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        _buildCounter('Custom amount (ml)', _amountPerServing, (v) => setState(() => _amountPerServing = v), unit: 'ml', step: 50, max: 2000),
        const SizedBox(height: 16),
        _buildCounter('Number of servings', _numberOfServings, (v) => setState(() => _numberOfServings = v), step: 1, min: 1, max: 20),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFF1565C0).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text('Total: ${_amountPerServing * _numberOfServings} ml',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodSection() {
    final eaten = FoodFluidIntakeLog.percentageFromPlate(_platePercentage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Meal Type', color: Colors.green),
        DropdownButtonFormField<String>(
          value: _mealType,
          decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.restaurant)),
          items: _mealOptions.map((t) => DropdownMenuItem(
            value: t,
            child: Row(children: [
              Icon(_mealIconFor(t), size: 20),
              const SizedBox(width: 8),
              Text(FoodFluidIntakeLog.mealLabel(t)),
            ]),
          )).toList(),
          onChanged: (v) => setState(() => _mealType = v!),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Did you observe the food?'),
          subtitle: Text(_foodObserved ? 'Yes' : 'No'),
          value: _foodObserved,
          activeColor: Colors.green,
          onChanged: (v) => setState(() => _foodObserved = v),
        ),
        if (_foodObserved) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('How much was eaten?'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _plateOptions.map((opt) {
              final isSelected = _platePercentage == opt['value'];
              return InkWell(
                onTap: () => setState(() => _platePercentage = opt['value']!),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(opt['value'] == 'none' ? '🍽️' : '🍽️ ${opt['percent']}', style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(opt['label']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    const Text('Eaten', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$eaten%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ]),
                  Column(children: [
                    const Text('Wasted', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${100 - eaten}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: eaten > 50 ? Colors.red : Colors.orange)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _foodDetailsController,
            decoration: const InputDecoration(
              labelText: 'Food Details (what was served?)',
              border: OutlineInputBorder(),
              hintText: 'e.g., Chicken soup, bread, apple',
            ),
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log != null ? 'Edit Intake Log' : 'New Intake Log'),
        backgroundColor: _logType == 'fluid' ? const Color(0xFF1565C0) : Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service user
            if (_loadingUsers)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedServiceUserId,
                decoration: const InputDecoration(
                  labelText: 'Service User *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedServiceUserId = v),
                validator: (v) => v == null ? 'Please select a service user' : null,
              ),
            const SizedBox(height: 16),

            // Log type toggle
            const Text('Log Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fluid', label: Text('Fluid'), icon: Icon(Icons.water_drop)),
                ButtonSegment(value: 'food', label: Text('Food'), icon: Icon(Icons.restaurant)),
              ],
              selected: <String>{_logType},
              onSelectionChanged: (s) => setState(() => _logType = s.first),
            ),
            const SizedBox(height: 16),

            // Date and time
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                    child: Text('${_logDate.day}/${_logDate.month}/${_logDate.year}'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                    child: Text(_logTime.format(context)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Assessor Name', border: OutlineInputBorder()),
              initialValue: _assessorName,
              onChanged: (v) => _assessorName = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            if (_logType == 'fluid') _buildFluidSection() else _buildFoodSection(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _logType == 'fluid' ? const Color(0xFF1565C0) : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
