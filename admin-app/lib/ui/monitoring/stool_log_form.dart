import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoolLogForm extends StatefulWidget {
  final String? serviceUserId;

  const StoolLogForm({super.key, this.serviceUserId});

  @override
  State<StoolLogForm> createState() => _StoolLogFormState();
}

class _StoolLogFormState extends State<StoolLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = Supabase.instance.client;

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  DateTime _logTime = DateTime.now();
  int? _bristolType;
  String? _colour;
  String? _amount;
  String? _notes;

  bool _isSubmitting = false;

  final List<String> _colourOptions = ['Brown', 'Dark Brown', 'Light Brown', 'Green', 'Yellow', 'Black', 'Red'];
  final List<String> _amountOptions = ['Small', 'Medium', 'Large'];

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await _service.from('service_users').select('id, name').order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_logTime));
    if (picked != null) {
      setState(() => _logTime = DateTime(
        _logTime.year, _logTime.month, _logTime.day,
        picked.hour, picked.minute,
      ));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service user')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.from('stool_logs').insert({
        'service_user_id': _selectedServiceUserId,
        'time': _logTime.toIso8601String(),
        'bristol_stool_type': _bristolType,
        'colour': _colour,
        'amount': _amount,
        'notes': _notes?.trim().isEmpty == true ? null : _notes,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildBristolCard(int type, Color color) {
    final isSelected = _bristolType == type;
    return GestureDetector(
      onTap: () => setState(() => _bristolType = type),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            Image.asset(
              'images/type_$type.png',
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.broken_image, size: 60, color: Colors.grey);
              },
            ),
            const SizedBox(height: 8),
            Text('$type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 4),
            Text(_getDescription(type), style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  String _getDescription(int type) {
    switch (type) {
      case 1: return 'Hard lumps';
      case 2: return 'Lumpy sausage';
      case 3: return 'Cracked sausage';
      case 4: return 'Smooth sausage';
      case 5: return 'Soft blobs';
      case 6: return 'Mushy';
      case 7: return 'Liquid';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stool Log'), backgroundColor: const Color(0xFF4CAF50)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service user selector
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
                validator: (v) => v == null ? 'Required' : null,
              ),
            const SizedBox(height: 16),

            // Time picker
            InkWell(
              onTap: _pickTime,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_logTime.hour.toString().padLeft(2, '0')}:${_logTime.minute.toString().padLeft(2, '0')}'),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bristol Stool Scale - Visual cards
            const Text('What does it look like?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _buildBristolCard(1, Colors.brown),
                _buildBristolCard(2, Colors.brown),
                _buildBristolCard(3, Colors.green),
                _buildBristolCard(4, Colors.green),
                _buildBristolCard(5, Colors.orange),
                _buildBristolCard(6, Colors.orange),
                _buildBristolCard(7, Colors.blue),
              ],
            ),
            const SizedBox(height: 24),

            // Colour selection
            const Text('Colour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _colourOptions.map((c) {
                Color color;
                switch (c.toLowerCase()) {
                  case 'brown': color = Colors.brown; break;
                  case 'dark brown': color = Colors.brown.shade800; break;
                  case 'light brown': color = Colors.brown.shade400; break;
                  case 'green': color = Colors.green; break;
                  case 'yellow': color = Colors.amber; break;
                  case 'black': color = Colors.black; break;
                  case 'red': color = Colors.red; break;
                  default: color = Colors.grey;
                }
                final isSelected = _colour == c;
                return GestureDetector(
                  onTap: () => setState(() => _colour = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.3) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? color : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(c, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Amount selection
            const Text('Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _amountOptions.map((a) {
                IconData icon;
                switch (a.toLowerCase()) {
                  case 'small': icon = Icons.remove_circle_outline; break;
                  case 'medium': icon = Icons.remove_red_eye_outlined; break;
                  case 'large': icon = Icons.add_circle_outline; break;
                  default: icon = Icons.remove_circle_outline;
                }
                final isSelected = _amount == a;
                return GestureDetector(
                  onTap: () => setState(() => _amount = a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.2) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : Colors.grey),
                        const SizedBox(width: 8),
                        Text(a, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Any observations...',
              ),
              onChanged: (v) => _notes = v,
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}