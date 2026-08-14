import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/care_record_service.dart';
import '../../services/auth_service.dart';
import '../../models/care_record.dart';

class CareRecordsScreen extends StatefulWidget {
  @override
  _CareRecordsScreenState createState() => _CareRecordsScreenState();
}

class _CareRecordsScreenState extends State<CareRecordsScreen> {
  late CareRecordService _careRecordService;
  late AuthService _authService;
  List<CareRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _careRecordService = CareRecordService();
    _authService = AuthService();
    _loadCareRecords();
  }

  Future<void> _loadCareRecords() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      final organisationId = userProfile?['organisation_id'] ?? '';
      if (organisationId.isNotEmpty) {
        final records = await _careRecordService.getCareRecords(organisationId);
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load care records: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Care Records'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(child: Text('No care records found'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(record.type),
                        subtitle: Text(record.description ?? ''),
                        trailing: Text(record.date.toLocal().toString()),
                      ),
                    );
                  },
                ),
    );
  }
}