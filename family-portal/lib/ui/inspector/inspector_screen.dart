import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/inspector_token_service.dart';
import '../../services/auth_service.dart';
import '../../models/inspector_token.dart';

class InspectorScreen extends StatefulWidget {
  @override
  _InspectorScreenState createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  late InspectorTokenService _inspectorTokenService;
  late AuthService _authService;
  List<InspectorToken> _tokens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inspectorTokenService = InspectorTokenService();
    _authService = AuthService();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      final organisationId = userProfile?['organisation_id'] ?? '';
      if (organisationId.isNotEmpty) {
        // For now, we'll just show a message since we don't have a method to get all tokens
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tokens: $e')),
      );
    }
  }

  Future<void> _generateToken() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      final organisationId = userProfile?['organisation_id'] ?? '';
      
      if (organisationId.isNotEmpty) {
        final token = await _inspectorTokenService.generateToken(
          'test-service-user',
          5,
          DateTime.now().add(Duration(hours: 24)),
          organisationId,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token generated: ${token.token}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate token: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspector Access'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Inspector Token',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text('Generate a token that allows inspectors to view care records without logging in.'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _generateToken,
                    child: Text('Generate Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Token Usage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Share the generated token with inspectors. They can use it to access care records for 24 hours or 5 views.'),
                ],
              ),
            ),
    );
  }
}