import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/carer_invite_service.dart';
import '../../services/supabase_auth_service.dart';

class CarerInviteScreen extends StatefulWidget {
  const CarerInviteScreen({super.key});

  @override
  State<CarerInviteScreen> createState() => _CarerInviteScreenState();
}

class _CarerInviteScreenState extends State<CarerInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobRoleController = TextEditingController();
  final _passwordController = TextEditingController();

  String _staffType = 'carer';
  bool _isSubmitting = false;

  static const _staffTypes = ['carer', 'driver', 'warehouse', 'factory', 'admin'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobRoleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final authService = context.read<SupabaseAuthService>();
      final organisationId = authService.organisationId;
      final invitedBy = authService.currentUser?.id;

      if (organisationId == null || organisationId.isEmpty) {
        throw Exception('No organisation found for this admin');
      }
      if (invitedBy == null) {
        throw Exception('Not authenticated');
      }

      final service = CarerInviteService(Supabase.instance.client);
      await service.createCarer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        jobRole: _jobRoleController.text.trim().isEmpty
            ? _staffType
            : _jobRoleController.text.trim(),
        staffType: _staffType,
        organisationId: organisationId,
        invitedBy: invitedBy,
        temporaryPassword: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carer invited successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite carer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Carer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _staffType,
              decoration: const InputDecoration(
                labelText: 'Staff Type',
                border: OutlineInputBorder(),
              ),
              items: _staffTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _staffType = v ?? 'carer'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jobRoleController,
              decoration: const InputDecoration(
                labelText: 'Job Role (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Temporary Password',
                helperText: 'Carer will use this to log in (min 6 chars)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Password is required';
                }
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_isSubmitting ? 'Inviting...' : 'Invite Carer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}