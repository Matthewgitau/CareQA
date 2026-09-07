import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _checkingEmail = false;
  List<Map<String, dynamic>> _matchingCarers = [];
  Map<String, dynamic>? _selectedCarer;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Please enter a valid email';
      });
      return;
    }

    setState(() {
      _checkingEmail = true;
      _error = null;
      _matchingCarers = [];
      _selectedCarer = null;
    });

    final authService = context.read<SupabaseAuthService>();
    final carers = await authService.findCarersByEmail(email);

    if (!mounted) return;

    setState(() {
      _checkingEmail = false;
      _matchingCarers = carers;
      if (carers.isEmpty) {
        _error = 'No staff record found for this email. '
            'Please contact your manager to be added to the system first.';
      }
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCarer == null) {
      setState(() {
        _error = 'Please select your staff record to confirm your identity';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authService = context.read<SupabaseAuthService>();
    final result = await authService.signUpAsStaff(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      carerId: _selectedCarer!['id'] as String,
      fullName: (_selectedCarer!['name'] as String?) ?? _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // AuthWrapper will detect the session and show the dashboard
    } else {
      setState(() {
        _error = result.errorMessage ?? 'Sign up failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create your staff account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your work email. If you are registered as staff, '
                'you will be able to select your record to confirm your identity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Work email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Check email button
              OutlinedButton.icon(
                onPressed: _checkingEmail ? null : _checkEmail,
                icon: _checkingEmail
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_checkingEmail ? 'Checking...' : 'Check my staff record'),
              ),
              const SizedBox(height: 16),

              // Matching carers selection
              if (_matchingCarers.isNotEmpty) ...[
                const Text(
                  'Select your staff record:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._matchingCarers.map((carer) {
                  final name = (carer['name'] as String?) ?? 'Staff';
                  final role = (carer['job_role'] as String?) ?? 'carer';
                  final isSelected = _selectedCarer?['id'] == carer['id'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                      title: Text(name),
                      subtitle: Text(role),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                      onTap: () {
                        setState(() {
                          _selectedCarer = carer;
                          _error = null;
                        });
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Confirm password
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create account', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}