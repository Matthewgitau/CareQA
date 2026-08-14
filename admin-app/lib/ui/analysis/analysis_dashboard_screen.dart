import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analysis_service.dart';

class AnalysisDashboardScreen extends StatefulWidget {
  const AnalysisDashboardScreen({super.key});

  @override
  State<AnalysisDashboardScreen> createState() => _AnalysisDashboardScreenState();
}

class _AnalysisDashboardScreenState extends State<AnalysisDashboardScreen> with SingleTickerProviderStateMixin {
  final _service = AnalysisService(Supabase.instance.client);
  bool _loading = true;
  Map<String, dynamic> _financialData = {};
  Map<String, dynamic> _complianceData = {};
  Map<String, dynamic> _operationalData = {};
  Map<String, dynamic> _staffData = {};
  Map<String, dynamic> _serviceUserData = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = now;

      final financial = await _service.getFinancialSummary(start, end);
      final compliance = await _service.getComplianceSummary(start, end);
      final operational = await _service.getOperationalSummary(start, end);
      final staff = await _service.getStaffMetrics(start, end);
      final serviceUser = await _service.getServiceUserMetrics(start, end);

      setState(() {
        _financialData = financial;
        _complianceData = compliance;
        _operationalData = operational;
        _staffData = staff;
        _serviceUserData = serviceUser;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Financial'),
            Tab(text: 'Compliance'),
            Tab(text: 'Operational'),
            Tab(text: 'Staff'),
            Tab(text: 'Service Users'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFinancialTab(),
                _buildComplianceTab(),
                _buildOperationalTab(),
                _buildStaffTab(),
                _buildServiceUserTab(),
              ],
            ),
    );
  }

  Widget _buildFinancialTab() {
    final revenue = _financialData['total_revenue'] ?? 0.0;
    final expenses = _financialData['total_expenses'] ?? 0.0;
    final profit = _financialData['net_profit'] ?? 0.0;
    final margin = _financialData['profit_margin'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards([
            _buildSummaryCard('Revenue', '£${revenue.toStringAsFixed(2)}', Colors.green),
            _buildSummaryCard('Expenses', '£${expenses.toStringAsFixed(2)}', Colors.red),
            _buildSummaryCard('Net Profit', '£${profit.toStringAsFixed(2)}', Colors.blue),
            _buildSummaryCard('Profit Margin', '${margin.toStringAsFixed(1)}%', Colors.purple),
          ]),
          const SizedBox(height: 24),
          const Text('Route Profitability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRouteProfitabilityTable(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Widget> cards) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildRouteProfitabilityTable() {
    final routes = _financialData['route_profitability'] as List<Map<String, dynamic>>? ?? [];

    if (routes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No route data available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Route', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Margin', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: routes.map((route) {
            final profit = route['profit'] ?? 0.0;
            final margin = route['profit_margin'] ?? 0.0;
            return DataRow(
              cells: [
                DataCell(Text(route['route_name'] ?? 'Unknown')),
                DataCell(Text('£${(route['revenue'] ?? 0.0).toStringAsFixed(2)}')),
                DataCell(Text('£${(route['expenses'] ?? 0.0).toStringAsFixed(2)}')),
                DataCell(Text('£${profit.toStringAsFixed(2)}', style: TextStyle(color: profit >= 0 ? Colors.green : Colors.red))),
                DataCell(Text('${margin.toStringAsFixed(1)}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildComplianceTab() {
    final training = _complianceData['training_compliance'] as Map<String, dynamic>? ?? {};
    final riskAssessment = _complianceData['risk_assessment_compliance'] as Map<String, dynamic>? ?? {};
    final audit = _complianceData['audit_compliance'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceCard('Training Compliance', training, Colors.blue),
          const SizedBox(height: 16),
          _buildComplianceCard('Risk Assessment Compliance', riskAssessment, Colors.orange),
          const SizedBox(height: 16),
          _buildComplianceCard('Audit Compliance', audit, Colors.green),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(String title, Map<String, dynamic> data, Color color) {
    final rate = data['compliance_rate'] ?? 0.0;
    final total = data['total_staff'] ?? data['total_service_users'] ?? 0;
    final completed = data['completed_training'] ?? data['with_assessments'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$completed / $total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${rate.toStringAsFixed(1)}% compliance', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: rate / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          strokeWidth: 8,
                        ),
                      ),
                      Text('${rate.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalTab() {
    final shiftCoverage = _operationalData['shift_coverage'] as Map<String, dynamic>? ?? {};
    final visitCompletion = _operationalData['visit_completion'] as Map<String, dynamic>? ?? {};
    final incidentTrends = _operationalData['incident_trends'] as List<Map<String, dynamic>>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard('Shift Coverage', shiftCoverage, Colors.blue),
          const SizedBox(height: 16),
          _buildMetricCard('Visit Completion', visitCompletion, Colors.green),
          const SizedBox(height: 16),
          const Text('Incident Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildIncidentTrends(incidentTrends),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, Map<String, dynamic> data, Color color) {
    final rate = data['completion_rate'] ?? data['coverage_rate'] ?? 0.0;
    final total = data['total_shifts'] ?? data['total_visits'] ?? 0;
    final completed = data['covered_shifts'] ?? data['completed_visits'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text('$completed / $total (${rate.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTrends(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No incident data available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Incidents by Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...trends.take(10).map((trend) {
              final date = trend['date'] ?? 'Unknown';
              final total = trend['total'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(date, style: const TextStyle(fontSize: 12))),
                    Text('$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTab() {
    final staffByRole = _staffData['staff_by_role'] as Map<String, int>? ?? {};
    final training = _staffData['training_completion'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff by Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildStaffByRoleChart(staffByRole),
          const SizedBox(height: 24),
          _buildMetricCard('Training Completion', training, Colors.purple),
          const SizedBox(height: 24),
          const Text('Staff List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildStaffList(),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Staff (from profiles)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.getStaff(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No staff found', style: TextStyle(color: Colors.grey));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final staff = snapshot.data![index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(staff['full_name'] ?? 'Unknown'),
                      subtitle: Text('${staff['role'] ?? 'No role'} • ${staff['email'] ?? ''}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffByRoleChart(Map<String, int> staffByRole) {
    if (staffByRole.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No staff data available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final total = staffByRole.values.fold(0, (sum, count) => sum + count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...staffByRole.entries.map((entry) {
              final role = entry.key;
              final count = entry.value;
              final percentage = total > 0 ? (count / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(role.toUpperCase())),
                        Text('$count (${percentage.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceUserTab() {
    final userCount = _serviceUserData['service_user_count'] ?? 0;
    final newAdmissions = _serviceUserData['new_admissions'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards([
            _buildSummaryCard('Total Service Users', userCount.toString(), Colors.blue),
            _buildSummaryCard('New Admissions', newAdmissions.toString(), Colors.green),
          ]),
          const SizedBox(height: 24),
          const Text('Service Users (from service_users)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildServiceUsersList(),
        ],
      ),
    );
  }

  Widget _buildServiceUsersList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Service Users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.getServiceUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No service users found', style: TextStyle(color: Colors.grey));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data![index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.home)),
                      title: Text(user['name'] ?? 'Unknown'),
                      subtitle: Text(user['email'] ?? ''),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Carers (from carers)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.getCarers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No carers found', style: TextStyle(color: Colors.grey));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final carer = snapshot.data![index];
                    final name = '${carer['first_name'] ?? ''} ${carer['last_name'] ?? ''}'.trim();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name.isEmpty ? 'Unknown' : name),
                      subtitle: Text(carer['email'] ?? ''),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
