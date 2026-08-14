import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/points_account.dart';
import '../../services/incentive_service.dart';

class PointsManagementScreen extends StatefulWidget {
  const PointsManagementScreen({super.key});

  @override
  State<PointsManagementScreen> createState() => _PointsManagementScreenState();
}

class _PointsManagementScreenState extends State<PointsManagementScreen> {
  final _service = IncentiveService(Supabase.instance.client);
  List<PointsAccount> _pointsAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await _service.getAllPointsBalances();
      if (mounted) {
        setState(() {
          _pointsAccounts = accounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading points: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points Management'),
        actions: [
          IconButton(
            onPressed: _loadPoints,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pointsAccounts.isEmpty
              ? const Center(child: Text('No points data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pointsAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _pointsAccounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getPointsColor(account.currentPointsBalance),
                          child: Text(
                            '${account.currentPointsBalance}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          account.staffName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.getBalanceStatus()),
                            Text('Earned: ${account.totalPointsEarned} • Redeemed: ${account.totalPointsRedeemed}'),
                          ],
                        ),
                        trailing: Icon(
                          Icons.emoji_events,
                          color: _getPointsColor(account.currentPointsBalance),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getPointsColor(int points) {
    if (points >= 1000) return Colors.amber;
    if (points >= 500) return Colors.grey;
    if (points >= 100) return Colors.brown;
    return Colors.purple;
  }
}