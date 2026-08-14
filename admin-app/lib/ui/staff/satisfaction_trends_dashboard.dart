import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/satisfaction_trend.dart';
import '../../services/satisfaction_service.dart';

class SatisfactionTrendsDashboard extends StatefulWidget {
  const SatisfactionTrendsDashboard({super.key});

  @override
  State<SatisfactionTrendsDashboard> createState() => _SatisfactionTrendsDashboardState();
}

class _SatisfactionTrendsDashboardState extends State<SatisfactionTrendsDashboard> {
  final _service = SatisfactionService(Supabase.instance.client);
  List<SatisfactionTrend> _trends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    setState(() => _isLoading = true);
    try {
      final trends = await _service.getTrends();
      if (mounted) {
        setState(() {
          _trends = trends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trends: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satisfaction Trends'),
        actions: [
          IconButton(
            onPressed: _loadTrends,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trends.isEmpty
              ? const Center(child: Text('No trend data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trends.length,
                  itemBuilder: (context, index) {
                    final trend = _trends[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Period Label
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  trend.periodLabel ?? '${DateFormat('MMM yyyy').format(trend.periodStart)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color(trend.getTrendColorValue()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    trend.getTrendStatus(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Scores Grid
                            Row(
                              children: [
                                Expanded(child: _buildScoreCard('Overall', trend.avgOverallSatisfaction)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildScoreCard('Engagement', trend.avgEngagementScore)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildScoreCard('Management', trend.avgManagementSupport)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildScoreCard('Environment', trend.avgWorkEnvironment)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildScoreCard('Career Dev', trend.avgCareerDevelopment)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildResponseRateCard(trend),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Top Strengths
                            if (trend.topStrengths.isNotEmpty) ...[
                              const Text('Top Strengths:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: trend.topStrengths
                                    .map((s) => Chip(
                                          label: Text(s, style: const TextStyle(fontSize: 12)),
                                          backgroundColor: Colors.green.shade100,
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Areas for Improvement
                            if (trend.topAreasForImprovement.isNotEmpty) ...[
                              const Text('Areas for Improvement:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: trend.topAreasForImprovement
                                    .map((s) => Chip(
                                          label: Text(s, style: const TextStyle(fontSize: 12)),
                                          backgroundColor: Colors.orange.shade100,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildScoreCard(String label, double? score) {
    final displayScore = score?.toStringAsFixed(1) ?? 'N/A';
    final color = score == null
        ? Colors.grey
        : score >= 8
            ? Colors.green
            : score >= 6
                ? Colors.orange
                : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayScore, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildResponseRateCard(SatisfactionTrend trend) {
    final responseRate = trend.responseRate;
    final displayRate = responseRate != null ? '${responseRate.toStringAsFixed(0)}%' : 'N/A';
    final color = responseRate == null
        ? Colors.grey
        : responseRate >= 70
            ? Colors.green
            : responseRate >= 50
                ? Colors.orange
                : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayRate, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const Text('Response Rate', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}