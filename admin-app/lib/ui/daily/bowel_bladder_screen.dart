import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/services/bowel_bladder_service.dart';
import 'package:admin_app/models/bowel_bladder_chart.dart';

class BowelBladderScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const BowelBladderScreen({
    super.key,
    required this.serviceUserId,
    required this.serviceUserName,
  });

  @override
  State<BowelBladderScreen> createState() => _BowelBladderScreenState();
}

class _BowelBladderScreenState extends State<BowelBladderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BowelBladderService _bowelBladderService;
  List<BowelBladderChartSummary> _chartSummaries = [];
  List<BowelBladderChart> _charts = [];
  bool _isLoading = true;
  String? _selectedChartId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bowelBladderService = Provider.of<BowelBladderService>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summaries = await _bowelBladderService.getChartSummariesForServiceUser(widget.serviceUserId);
      final charts = await _bowelBladderService.getChartsForServiceUser(widget.serviceUserId);
      
      setState(() {
        _chartSummaries = summaries;
        _charts = charts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bowel & Bladder Charts - ${widget.serviceUserName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'View Charts'),
            Tab(text: 'Edit Chart'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViewChartsTab(),
          _buildEditChartTab(),
        ],
      ),
    );
  }

  Widget _buildViewChartsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chartSummaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No bowel & bladder charts found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Service User: ${widget.serviceUserName}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _chartSummaries.length,
        itemBuilder: (context, index) {
          final chart = _chartSummaries[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: chart.warningTriggered ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.warning_amber, color: Colors.white, size: 20),
              ),
              title: Row(
                children: [
                  Text(
                    '${chart.chartDate.day}/${chart.chartDate.month}/${chart.chartDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${chart.daysSinceLastBowel} days',
                    style: TextStyle(
                      color: chart.warningTriggered ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chart.warningTriggered ? 'WARNING: Constipation risk' : 'Normal',
                    style: TextStyle(
                      color: chart.warningTriggered ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Bowel: ${chart.bowelEntryCount}, Bladder: ${chart.bladderEntryCount}'),
                  Text('Total volume: ${chart.totalBladderVolume} ml'),
                  if (chart.hasIncontinence) Text('Incontinence events: Yes', style: const TextStyle(color: Colors.orange)),
                  if (chart.createdBy != null) Text('Created by: ${chart.createdBy}'),
                  if (chart.updatedBy != null && chart.updatedBy != chart.createdBy)
                    Text('Last edited by: ${chart.updatedBy}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                setState(() {
                  _selectedChartId = chart.id;
                  _tabController.index = 1; // Switch to Edit tab
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditChartTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedChartId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Select a chart to edit',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap a chart from the View Charts tab',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final selectedChart = _charts.firstWhere((chart) => chart.id == _selectedChartId, orElse: () => _charts.first);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chart Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Date:'),
                      const SizedBox(width: 16),
                      Text(
                        '${selectedChart.chartDate.day}/${selectedChart.chartDate.month}/${selectedChart.chartDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Days since last bowel:'),
                      const SizedBox(width: 16),
                      Text(
                        '${selectedChart.daysSinceLastBowel}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selectedChart.warningTriggered ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Warning triggered:'),
                      const SizedBox(width: 16),
                      Text(
                        selectedChart.warningTriggered ? 'Yes' : 'No',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selectedChart.warningTriggered ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Total bladder volume:'),
                      const SizedBox(width: 16),
                      Text('${selectedChart.getTotalBladderVolume()} ml'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Incontinence events:'),
                      const SizedBox(width: 16),
                      Text(
                        selectedChart.hasIncontinenceEvents() ? 'Yes' : 'No',
                        style: TextStyle(
                          color: selectedChart.hasIncontinenceEvents() ? Colors.orange : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedChart.createdBy != null)
                    Text(
                      'Created by: ${selectedChart.createdBy} on ${selectedChart.createdAt?.toLocal().toIso8601String() ?? 'Unknown'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  if (selectedChart.updatedBy != null && selectedChart.updatedBy != selectedChart.createdBy)
                    Text(
                      'Last edited by: ${selectedChart.updatedBy} on ${selectedChart.updatedAt?.toLocal().toIso8601String() ?? 'Unknown'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Edit Form
          _buildEditForm(selectedChart),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _saveChart(selectedChart),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewAuditHistory(selectedChart.id!),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('View Audit History'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Delete Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _deleteChart(selectedChart.id!),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Delete Chart', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(BowelBladderChart chart) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Bowel Entries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (chart.bowelEntries.isEmpty)
              const Center(
                child: Text(
                  'No bowel entries yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chart.bowelEntries.length,
              itemBuilder: (context, index) => _buildEditBowelEntry(chart, index),
            ),

            const SizedBox(height: 16),

            const Text(
              'Edit Bladder Entries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (chart.bladderEntries.isEmpty)
              const Center(
                child: Text(
                  'No bladder entries yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chart.bladderEntries.length,
              itemBuilder: (context, index) => _buildEditBladderEntry(chart, index),
            ),

            const SizedBox(height: 16),

            // Days since last bowel
            const Text('Days Since Last Bowel Movement', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: chart.daysSinceLastBowel.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter number of days',
              ),
              onChanged: (value) {
                final days = int.tryParse(value) ?? 0;
                setState(() {
                  chart.daysSinceLastBowel = days;
                  chart.warningTriggered = chart.checkWarningTriggered();
                });
              },
            ),

            const SizedBox(height: 16),

            // Notes
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: chart.notes ?? '',
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Additional notes...',
              ),
              onChanged: (value) {
                setState(() {
                  chart.notes = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditBowelEntry(BowelBladderChart chart, int index) {
    final entry = chart.bowelEntries[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bowel Entry ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      chart.bowelEntries.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Time
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 8),
                Text(entry.time.formatTime()),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Implement time picker
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Bristol Stool Type
            Row(
              children: [
                const Text('Bristol Type:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: entry.bristolStoolType,
                    items: [1, 2, 3, 4, 5, 6, 7].map((type) {
                      return DropdownMenuItem<int>(
                        value: type,
                        child: Text('$type - ${entry.getBristolDescription()}'),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        chart.bowelEntries[index] = BowelEntry(
                          time: entry.time,
                          bristolStoolType: value!,
                          consistency: entry.consistency,
                          colour: entry.colour,
                          amount: entry.amount,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Consistency
            Row(
              children: [
                const Text('Consistency:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.consistency,
                    items: BristolStoolScale.consistencies.map((consistency) {
                      return DropdownMenuItem<String>(
                        value: consistency,
                        child: Text(consistency),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        chart.bowelEntries[index] = BowelEntry(
                          time: entry.time,
                          bristolStoolType: entry.bristolStoolType,
                          consistency: value!,
                          colour: entry.colour,
                          amount: entry.amount,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Colour
            Row(
              children: [
                const Text('Colour:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.colour,
                    items: BristolStoolScale.colours.map((colour) {
                      return DropdownMenuItem<String>(
                        value: colour,
                        child: Text(colour),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        chart.bowelEntries[index] = BowelEntry(
                          time: entry.time,
                          bristolStoolType: entry.bristolStoolType,
                          consistency: entry.consistency,
                          colour: value!,
                          amount: entry.amount,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Amount
            Row(
              children: [
                const Text('Amount:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.amount,
                    items: BristolStoolScale.amounts.map((amount) {
                      return DropdownMenuItem<String>(
                        value: amount,
                        child: Text(amount),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        chart.bowelEntries[index] = BowelEntry(
                          time: entry.time,
                          bristolStoolType: entry.bristolStoolType,
                          consistency: entry.consistency,
                          colour: entry.colour,
                          amount: value!,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditBladderEntry(BowelBladderChart chart, int index) {
    final entry = chart.bladderEntries[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bladder Entry ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      chart.bladderEntries.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Time
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 8),
                Text(entry.time.formatTime()),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Implement time picker
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Urine Colour
            Row(
              children: [
                const Text('Urine Colour:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.urineColour,
                    items: UrineColours.colours.map((colour) {
                      return DropdownMenuItem<String>(
                        value: colour,
                        child: Text(colour),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        chart.bladderEntries[index] = BladderEntry(
                          time: entry.time,
                          urineColour: value!,
                          volumeMl: entry.volumeMl,
                          incontinence: entry.incontinence,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Volume
            Row(
              children: [
                const Text('Volume (ml):'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.volumeMl.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final volume = int.tryParse(value) ?? 0;
                      setState(() {
                        chart.bladderEntries[index] = BladderEntry(
                          time: entry.time,
                          urineColour: entry.urineColour,
                          volumeMl: volume,
                          incontinence: entry.incontinence,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Incontinence
            Row(
              children: [
                const Text('Incontinence:'),
                const SizedBox(width: 8),
                Switch(
                  value: entry.incontinence,
                  onChanged: (value) {
                    setState(() {
                      chart.bladderEntries[index] = BladderEntry(
                        time: entry.time,
                        urineColour: entry.urineColour,
                        volumeMl: entry.volumeMl,
                        incontinence: value,
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChart(BowelBladderChart chart) async {
    setState(() => _isLoading = true);
    try {
      final updates = {
        'entries': chart.entries,
        'days_since_last_bowel': chart.daysSinceLastBowel,
        'warning_triggered': chart.warningTriggered,
        'notes': chart.notes,
      };

      await _bowelBladderService.updateChart(chart.id!, updates, ''); // Would come from auth context
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart updated successfully')),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating chart: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChart(String chartId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chart'),
        content: const Text('Are you sure you want to delete this chart? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _bowelBladderService.deleteChart(chartId, ''); // Would come from auth context
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chart deleted successfully')),
        );
        
        await _loadData();
        setState(() {
          _selectedChartId = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting chart: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _viewAuditHistory(String chartId) {
    // TODO: Implement audit history viewer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit history viewer coming soon')),
    );
  }
}

extension TimeFormatting on DateTime {
  String formatTime() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}