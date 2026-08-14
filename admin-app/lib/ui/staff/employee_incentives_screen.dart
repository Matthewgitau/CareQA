import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/employee_incentive.dart';
import '../../models/points_account.dart';
import '../../services/incentive_service.dart';
import 'incentive_form.dart';
import 'points_management_screen.dart';

class EmployeeIncentivesScreen extends StatefulWidget {
  const EmployeeIncentivesScreen({super.key});

  @override
  State<EmployeeIncentivesScreen> createState() => _EmployeeIncentivesScreenState();
}

class _EmployeeIncentivesScreenState extends State<EmployeeIncentivesScreen> with SingleTickerProviderStateMixin {
  final _service = IncentiveService(Supabase.instance.client);
  List<EmployeeIncentive> _incentives = [];
  List<PointsAccount> _pointsAccounts = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final incentives = await _service.getIncentives();
      final pointsAccounts = await _service.getAllPointsBalances();
      if (mounted) {
        setState(() {
          _incentives = incentives;
          _pointsAccounts = pointsAccounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Incentives & Rewards'),
        actions: [
          IconButton(
            onPressed: _addIncentive,
            icon: const Icon(Icons.add),
            tooltip: 'New Incentive',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Dashboard Cards
                _buildDashboardCards(),
                // Tab Bar
                Container(
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _selectedIndex = 0),
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedIndex == 0 ? Colors.purple : Colors.transparent,
                            foregroundColor: _selectedIndex == 0 ? Colors.white : Colors.black87,
                          ),
                          child: const Text('Incentives'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _selectedIndex = 1),
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedIndex == 1 ? Colors.purple : Colors.transparent,
                            foregroundColor: _selectedIndex == 1 ? Colors.white : Colors.black87,
                          ),
                          child: const Text('Leaderboard'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _selectedIndex == 0 ? _buildIncentivesList() : _buildLeaderboard(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedIndex == 0 ? _addIncentive : _viewPointsManagement,
        child: Icon(_selectedIndex == 0 ? Icons.card_giftcard : Icons.stars),
      ),
    );
  }

  Widget _buildDashboardCards() {
    final totalPoints = _pointsAccounts.fold<int>(0, (sum, account) => sum + account.currentPointsBalance);
    final topPerformer = _pointsAccounts.isNotEmpty ? _pointsAccounts.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.purple.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Points',
              totalPoints.toString(),
              Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Awards',
              _incentives.length.toString(),
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Top Performer',
              topPerformer?.staffName ?? 'N/A',
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildIncentivesList() {
    if (_incentives.isEmpty) {
      return const Center(child: Text('No incentives found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incentives.length,
      itemBuilder: (context, index) {
        final incentive = _incentives[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text('${incentive.pointsAwarded}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(
              incentive.staffName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incentive.getIncentiveTypeDisplay()),
                Text('${DateFormat('dd/MM/yyyy').format(incentive.awardDate)} • ${incentive.awardTitle}'),
                if (incentive.monetaryValue > 0)
                  Text('Value: £${incentive.monetaryValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (incentive.isPublic)
                  const Icon(Icons.public, size: 16, color: Colors.blue),
                if (incentive.redeemed)
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
              ],
            ),
            onTap: () => _viewIncentiveDetails(incentive),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboard() {
    if (_pointsAccounts.isEmpty) {
      return const Center(child: Text('No points data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pointsAccounts.length,
      itemBuilder: (context, index) {
        final account = _pointsAccounts[index];
        final medalColor = index == 0 ? Colors.amber : index == 1 ? Colors.grey : index == 2 ? Colors.brown : Colors.purple;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: medalColor,
              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(
              account.staffName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(account.getBalanceStatus()),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${account.currentPointsBalance} pts',
                style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  void _viewIncentiveDetails(EmployeeIncentive incentive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incentive.getIncentiveTypeDisplay()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Staff', incentive.staffName),
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(incentive.awardDate)),
              _buildDetailRow('Title', incentive.awardTitle),
              _buildDetailRow('Points', '${incentive.pointsAwarded}'),
              if (incentive.monetaryValue > 0)
                _buildDetailRow('Value', '£${incentive.monetaryValue.toStringAsFixed(2)}'),
              _buildDetailRow('Reason', incentive.awardReason),
              if (incentive.nominatedByName != null)
                _buildDetailRow('Nominated by', incentive.nominatedByName!),
              if (incentive.awardDescription != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Description:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(incentive.awardDescription!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addIncentive() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncentiveFormScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _viewPointsManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PointsManagementScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }
}
