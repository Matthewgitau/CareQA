import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/care_record_service.dart';
import '../../services/visit_log_service.dart';
import '../../services/auth_service.dart';
import '../../models/care_record.dart';
import '../../models/visit_log.dart';

class FamilyDashboard extends StatefulWidget {
  @override
  _FamilyDashboardState createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  late CareRecordService _careRecordService;
  late VisitLogService _visitLogService;
  late AuthService _authService;
  List<CareRecord> _recentRecords = [];
  List<VisitLog> _recentVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _careRecordService = CareRecordService();
    _visitLogService = VisitLogService();
    _authService = AuthService();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      final organisationId = userProfile?['organisation_id'] ?? '';
      if (organisationId.isNotEmpty) {
        final records = await _careRecordService.getCareRecords(organisationId);
        final visits = await _visitLogService.getVisitLogs(organisationId);
        
        setState(() {
          _recentRecords = records.take(5).toList();
          _recentVisits = visits.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Care Records',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _recentRecords.isEmpty
                      ? Text('No recent care records')
                      : Column(
                          children: _recentRecords.map((record) {
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(record.type),
                                subtitle: Text(record.description ?? ''),
                                trailing: Text(record.date.toLocal().toString()),
                              ),
                            );
                          }).toList(),
                        ),
                  SizedBox(height: 20),
                  Text(
                    'Recent Visits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _recentVisits.isEmpty
                      ? Text('No recent visits')
                      : Column(
                          children: _recentVisits.map((visit) {
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(visit.serviceUser.name),
                                subtitle: Text(visit.notes),
                                trailing: Text(visit.visitDate.toLocal().toString()),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }
}