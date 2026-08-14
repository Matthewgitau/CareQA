import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RespectForm extends StatefulWidget {
  final String? assessmentId;

  const RespectForm({
    super.key,
    this.assessmentId,
  });

  @override
  State<RespectForm> createState() => _RespectFormState();
}

class _RespectFormState extends State<RespectForm> {
  final _client = Supabase.instance.client;
  bool _saving = false;
  String? _assessmentId;
  String? _selectedServiceUserId;
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;

  // Assessment metadata
  DateTime _assessmentDate = DateTime.now();
  final _assessorNameController = TextEditingController();
  final _signatureController = TextEditingController();
  bool _signatureConfirmed = false;

  // RESPECT framework sections
  final _whatMattersToMeController = TextEditingController();
  final _communicationNeedsController = TextEditingController();
  final _healthAndWellbeingController = TextEditingController();
  final _dailyLivingController = TextEditingController();
  final _relationshipsController = TextEditingController();
  final _spiritualCulturalController = TextEditingController();
  final _endOfLifeWishesController = TextEditingController();
  final _preferredPlaceOfCareController = TextEditingController();
  final _whoToContactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _assessmentId = widget.assessmentId;
    _loadServiceUsers();
    final user = _client.auth.currentUser;
    if (user != null) {
      _assessorNameController.text = user.email?.split('@').first ?? user.id ?? '';
    }
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await _client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<Map<String, dynamic>?> _getServiceUserDetails(String userId) async {
    try {
      final response = await _client
          .from('service_users')
          .select('name, date_of_birth')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _assessmentDate = picked);
    }
  }

  @override
  void dispose() {
    _assessorNameController.dispose();
    _signatureController.dispose();
    _whatMattersToMeController.dispose();
    _communicationNeedsController.dispose();
    _healthAndWellbeingController.dispose();
    _dailyLivingController.dispose();
    _relationshipsController.dispose();
    _spiritualCulturalController.dispose();
    _endOfLifeWishesController.dispose();
    _preferredPlaceOfCareController.dispose();
    _whoToContactController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _save() async {
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user')),
      );
      return;
    }
    if (_assessorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the assessor name')),
      );
      return;
    }

    final serviceUserDetails = await _getServiceUserDetails(_selectedServiceUserId!);
    if (serviceUserDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find service user details')),
      );
      return;
    }
    final serviceUserName = (serviceUserDetails['name'] as String?) ?? '';
    final dateOfBirth = serviceUserDetails['date_of_birth']?.toString() ?? DateTime.now().toIso8601String();

    setState(() => _saving = true);
    try {
      final status = _signatureConfirmed ? 'completed' : 'draft';
      final signatureData = _signatureConfirmed ? _signatureController.text.trim() : null;

      final payload = {
        'service_user_id': _selectedServiceUserId,
        'service_user_name': serviceUserName,
        'date_of_birth': dateOfBirth,
        'assessor_name': _assessorNameController.text.trim(),
        'assessment_date': _assessmentDate.toIso8601String(),
        'what_matters_to_me': _whatMattersToMeController.text.trim().isEmpty ? null : _whatMattersToMeController.text.trim(),
        'communication_needs': _communicationNeedsController.text.trim().isEmpty ? null : _communicationNeedsController.text.trim(),
        'health_and_wellbeing': _healthAndWellbeingController.text.trim().isEmpty ? null : _healthAndWellbeingController.text.trim(),
        'daily_living': _dailyLivingController.text.trim().isEmpty ? null : _dailyLivingController.text.trim(),
        'relationships': _relationshipsController.text.trim().isEmpty ? null : _relationshipsController.text.trim(),
        'spiritual_cultural': _spiritualCulturalController.text.trim().isEmpty ? null : _spiritualCulturalController.text.trim(),
        'end_of_life_wishes': _endOfLifeWishesController.text.trim().isEmpty ? null : _endOfLifeWishesController.text.trim(),
        'preferred_place_of_care': _preferredPlaceOfCareController.text.trim().isEmpty ? null : _preferredPlaceOfCareController.text.trim(),
        'who_to_contact': _whoToContactController.text.trim().isEmpty ? null : _whoToContactController.text.trim(),
        'signature_data': signatureData,
        'status': status,
      };

      if (_assessmentId == null) {
        final data = await _client.from('respect_forms').insert({
          ...payload,
          'created_by': _client.auth.currentUser?.id,
        }).select().single();
        _assessmentId = data['id'] as String?;
      } else if (_assessmentId != null) {
        await _client.from('respect_forms').update({
          ...payload,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _assessmentId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'completed' ? 'RESPECT form saved successfully' : 'RESPECT form saved as draft')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSectionField(String title, IconData icon, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1565C0), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter details...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RESPECT Form'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'RESPECT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Record of Service User Preferences',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          // Service user dropdown
          Padding(
            padding: const EdgeInsets.all(12),
            child: _loadingUsers
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedServiceUserId,
                    decoration: InputDecoration(
                      labelText: 'Service User *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    items: _serviceUsers.map((user) {
                      return DropdownMenuItem(
                        value: user['id'] as String,
                        child: Text(user['name']?.toString() ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedServiceUserId = value),
                  ),
          ),

          // Assessment Date + Assessor Name row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Assessment Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(_formatDate(_assessmentDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _assessorNameController,
                    decoration: InputDecoration(
                      labelText: 'Assessor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.badge, size: 18),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // RESPECT sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildSectionField('What Matters to Me', Icons.favorite_border, _whatMattersToMeController),
                _buildSectionField('Communication Needs', Icons.chat_bubble_outline, _communicationNeedsController),
                _buildSectionField('Health & Wellbeing', Icons.health_and_safety, _healthAndWellbeingController),
                _buildSectionField('Daily Living', Icons.home, _dailyLivingController),
                _buildSectionField('Relationships', Icons.people_outline, _relationshipsController),
                _buildSectionField('Spiritual & Cultural', Icons.church_outlined, _spiritualCulturalController),
                _buildSectionField('End of Life Wishes', Icons.nightlight_round, _endOfLifeWishesController),
                _buildSectionField('Preferred Place of Care', Icons.local_hospital_outlined, _preferredPlaceOfCareController),
                _buildSectionField('Who to Contact', Icons.contact_phone, _whoToContactController),

                const SizedBox(height: 12),

                // Signature
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text(
                            'I confirm that I have completed this form to the best of my knowledge',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _signatureConfirmed,
                          activeColor: const Color(0xFF1565C0),
                          onChanged: (v) => setState(() => _signatureConfirmed = v ?? false),
                        ),
                        if (_signatureConfirmed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: TextField(
                              controller: _signatureController,
                              decoration: InputDecoration(
                                labelText: 'Assessor Signature (type your name)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.edit_note),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save RESPECT Form'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}