import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/visit_log_service.dart';
import '../../services/auth_service.dart';
import '../../models/visit_log.dart';

class VisitsScreen extends StatefulWidget {
  @override
  _VisitsScreenState createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  late VisitLogService _visitLogService;
  late AuthService _authService;
  List<VisitLog> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _visitLogService = VisitLogService();
    _authService = AuthService();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      final organisationId = userProfile?['organisation_id'] ?? '';
      if (organisationId.isNotEmpty) {
        final visits = await _visitLogService.getVisitLogs(organisationId);
        setState(() {
          _visits = visits;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load visits: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Visits'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _visits.isEmpty
              ? Center(child: Text('No visits found'))
              : ListView.builder(
                  itemCount: _visits.length,
                  itemBuilder: (context, index) {
                    final visit = _visits[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(visit.serviceUser.name),
                        subtitle: Text('${visit.carerName} - ${visit.notes ?? ''}'),
                        trailing: Text(visit.visitStart.toLocal().toString()),
                      ),
                    );
                  },
                ),
    );
  }
}