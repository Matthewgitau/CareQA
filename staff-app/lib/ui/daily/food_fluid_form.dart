import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/services/food_fluid_service.dart';
import 'package:staff_app/models/food_fluid_chart.dart';

class FoodFluidForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const FoodFluidForm({
    super.key,
    required this.serviceUserId,
    required this.serviceUserName,
  });

  @override
  State<FoodFluidForm> createState() => _FoodFluidFormState();
}

class _FoodFluidFormState extends State<FoodFluidForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Meal entries with default structure
  final Map<String, Map<String, dynamic>> _mealEntries = {
    'breakfast': {
      'time': '',
      'foodOffered': '',
      'foodEaten': 'All',
      'fluidType': '',
      'fluidAmount': 0,
    },
    'midMorning': {
      'time': '',
      'foodOffered': '',
      'foodEaten': 'All',
      'fluidType': '',
      'fluidAmount': 0,
    },
    'lunch': {
      'time': '',
      'foodOffered': '',
      'foodEaten': 'All',
      'fluidType': '',
      'fluidAmount': 0,
    },
    'afternoon': {
      'time': '',
      'foodOffered': '',
      'foodEaten': 'All',
      'fluidType': '',
      'fluidAmount': 0,
    },
    'eveningMeal': {
      'time': '',
      'foodOffered': '',
      'foodEaten': 'All',
      'fluidType': '',
      'fluidAmount': 0,
    },
    'supper': {
      'time': '',
      'foodOffered': '',
      'foodEaten': 'All',
      'fluidType': '',
      'fluidAmount': 0,
    },
  };

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateMealEntry(String mealKey, String field, dynamic value) {
    setState(() {
      _mealEntries[mealKey]![field] = value;
    });
  }

  int _calculateTotalFluid() {
    int total = 0;
    for (final meal in _mealEntries.values) {
      final fluidAmount = meal['fluidAmount'] as int?;
      if (fluidAmount != null) {
        total += fluidAmount;
      }
    }
    return total;
  }

  bool _checkFluidTargetMet() {
    return _calculateTotalFluid() >= 1500;
  }

  Future<void> _submitFoodFluidChart() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final foodFluidService = FoodFluidService(Supabase.instance.client);
        final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

        final chart = FoodFluidChart(
          serviceUserId: widget.serviceUserId,
          chartDate: _selectedDate,
          entries: _mealEntries,
          totalFluidMl: _calculateTotalFluid(),
          fluidTargetMet: _checkFluidTargetMet(),
          notes: _notesController.text.trim(),
        );

        await foodFluidService.createChart(chart, currentUserId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food & Fluid Chart submitted successfully')),
        );

        Navigator.pop(context, true); // Return success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting food & fluid chart: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food & Fluid Chart - ${widget.serviceUserName}'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Date Picker
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chart Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Date:'),
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed: _selectDate,
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Service User: ${widget.serviceUserName}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meal Sections
                  _buildMealSection('breakfast', 'Breakfast'),
                  _buildMealSection('midMorning', 'Mid-Morning'),
                  _buildMealSection('lunch', 'Lunch'),
                  _buildMealSection('afternoon', 'Afternoon'),
                  _buildMealSection('eveningMeal', 'Evening Meal'),
                  _buildMealSection('supper', 'Supper'),

                  const SizedBox(height: 16),

                  // Summary
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Fluid Intake:'),
                              Text(
                                '${_calculateTotalFluid()} ml',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Fluid Target Met:'),
                              Text(
                                _checkFluidTargetMet() ? 'Yes' : 'No',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _checkFluidTargetMet() ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                              hintText: 'Any additional observations or comments...',
                            ),
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitFoodFluidChart,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Submit Food & Fluid Chart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMealSection(String mealKey, String mealName) {
    final mealData = _mealEntries[mealKey]!;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Time
            TextFormField(
              initialValue: mealData['time'],
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
                hintText: 'e.g., 08:00',
              ),
              onChanged: (value) => _updateMealEntry(mealKey, 'time', value),
            ),
            const SizedBox(height: 12),

            // Food Offered
            TextFormField(
              initialValue: mealData['foodOffered'],
              decoration: const InputDecoration(
                labelText: 'Food Offered',
                border: OutlineInputBorder(),
                hintText: 'What was offered',
              ),
              onChanged: (value) => _updateMealEntry(mealKey, 'foodOffered', value),
            ),
            const SizedBox(height: 12),

            // Food Eaten
            Row(
              children: [
                const Text('Food Eaten:'),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: mealData['foodEaten'],
                  items: FoodFluidConstants.foodEatenOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) => _updateMealEntry(mealKey, 'foodEaten', value),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fluid Type
            TextFormField(
              initialValue: mealData['fluidType'],
              decoration: const InputDecoration(
                labelText: 'Fluid Type',
                border: OutlineInputBorder(),
                hintText: 'e.g., Water, Tea, Juice',
              ),
              onChanged: (value) => _updateMealEntry(mealKey, 'fluidType', value),
            ),
            const SizedBox(height: 12),

            // Fluid Amount
            TextFormField(
              initialValue: mealData['fluidAmount'].toString(),
              decoration: const InputDecoration(
                labelText: 'Fluid Amount (ml)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 200',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = int.tryParse(value) ?? 0;
                _updateMealEntry(mealKey, 'fluidAmount', amount);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}