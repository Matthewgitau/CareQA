import 'package:flutter/material.dart';
import 'package:staff_app/models/equipment_register_assessment.dart';
import 'package:staff_app/services/equipment_register_service.dart';
import 'package:staff_app/ui/risk/equipment_register_form.dart';
import 'package:supabase/supabase.dart';

class EquipmentRegisterScreen extends StatefulWidget {
  const EquipmentRegisterScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentRegisterScreen> createState() => _EquipmentRegisterScreenState();
}

class _EquipmentRegisterScreenState extends State<EquipmentRegisterScreen> {
  late final EquipmentRegisterService _equipmentService;
  late Future<List<EquipmentRegisterAssessment>> _equipmentFuture;
  List<EquipmentRegisterAssessment> _allEquipment = [];
  List<EquipmentRegisterAssessment> _filteredEquipment = [];
  String _searchQuery = '';
  String _filterCategory = 'all';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _equipmentService = EquipmentRegisterService(SupabaseClient('https://your-project.supabase.co', 'your-anon-key'));
    _equipmentFuture = _loadEquipment();
  }

  Future<List<EquipmentRegisterAssessment>> _loadEquipment() async {
    try {
      final equipment = await _equipmentService.getAssessments();
      setState(() {
        _allEquipment = equipment;
        _filteredEquipment = equipment;
      });
      return equipment;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load equipment: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  void _filterEquipment() {
    setState(() {
      _filteredEquipment = _allEquipment.where((equipment) {
        // Search filter
        final searchMatch = _searchQuery.isEmpty ||
            equipment.equipmentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            equipment.equipmentId.toLowerCase().contains(_searchQuery.toLowerCase());

        // Category filter
        final categoryMatch = _filterCategory == 'all' || 
            equipment.equipmentCategory == _filterCategory;

        // Status filter
        final statusMatch = _filterStatus == 'all' || _getStatusMatch(equipment, _filterStatus);

        return searchMatch && categoryMatch && statusMatch;
      }).toList();
    });
  }

  bool _getStatusMatch(EquipmentRegisterAssessment equipment, String status) {
    switch (status) {
      case 'safe':
        return equipment.isSafeForUse;
      case 'unsafe':
        return !equipment.isSafeForUse;
      case 'service_due':
        return equipment.serviceDue;
      case 'expired_tests':
        return equipment.lolerExpired || equipment.patExpired;
      case 'faults':
        return equipment.reportedFaults != 'none';
      case 'high_risk':
        return equipment.riskLevel == 'critical' || equipment.riskLevel == 'high';
      default:
        return true;
    }
  }

  void _showEquipmentDetails(EquipmentRegisterAssessment equipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentRegisterForm(assessment: equipment),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _equipmentFuture = _loadEquipment();
        });
      }
    });
  }

  void _addNewEquipment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EquipmentRegisterForm(),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _equipmentFuture = _loadEquipment();
        });
      }
    });
  }

  void _showEquipmentActions(EquipmentRegisterAssessment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Equipment Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!equipment.isSafeForUse)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Safe'),
                onTap: () {
                  Navigator.pop(context);
                  _markEquipmentSafe(equipment);
                },
              ),
            if (equipment.isSafeForUse)
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Mark as Unsafe'),
                onTap: () {
                  Navigator.pop(context);
                  _markEquipmentUnsafe(equipment);
                },
              ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report Fault'),
              onTap: () {
                Navigator.pop(context);
                _reportFault(equipment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Colors.blue),
              title: const Text('Mark Staff Trained'),
              onTap: () {
                Navigator.pop(context);
                _markStaffTrained(equipment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Equipment'),
              onTap: () {
                Navigator.pop(context);
                _deleteEquipment(equipment);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _markEquipmentSafe(EquipmentRegisterAssessment equipment) async {
    try {
      await _equipmentService.markEquipmentSafe(equipment.id!);
      setState(() {
        _equipmentFuture = _loadEquipment();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment marked as safe'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark equipment as safe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markEquipmentUnsafe(EquipmentRegisterAssessment equipment) async {
    try {
      await _equipmentService.markEquipmentUnsafe(equipment.id!);
      setState(() {
        _equipmentFuture = _loadEquipment();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment marked as unsafe'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark equipment as unsafe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reportFault(EquipmentRegisterAssessment equipment) {
    showDialog(
      context: context,
      builder: (context) {
        String faultType = 'minor';
        String actionRequired = '';

        return AlertDialog(
          title: const Text('Report Fault'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: faultType,
                decoration: const InputDecoration(labelText: 'Fault Type'),
                items: const [
                  DropdownMenuItem(value: 'minor', child: Text('Minor')),
                  DropdownMenuItem(value: 'major', child: Text('Major')),
                ],
                onChanged: (value) {
                  faultType = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Action Required',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  actionRequired = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _equipmentService.reportFault(equipment.id!, faultType, actionRequired.isNotEmpty ? actionRequired : null);
                  setState(() {
                    _equipmentFuture = _loadEquipment();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fault reported successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to report fault: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Report Fault'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markStaffTrained(EquipmentRegisterAssessment equipment) async {
    showDialog(
      context: context,
      builder: (context) {
        bool trainingRecordAvailable = false;
        return AlertDialog(
          title: const Text('Mark Staff as Trained'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Training Record Available'),
                value: trainingRecordAvailable,
                onChanged: (value) {
                  setState(() {
                    trainingRecordAvailable = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _equipmentService.markStaffTrained(equipment.id!, trainingRecordAvailable);
                  setState(() {
                    _equipmentFuture = _loadEquipment();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Staff marked as trained'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to mark staff as trained: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Mark Trained'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEquipment(EquipmentRegisterAssessment equipment) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Are you sure you want to delete ${equipment.equipmentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _equipmentService.deleteAssessment(equipment.id!);
        setState(() {
          _equipmentFuture = _loadEquipment();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete equipment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Register'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewEquipment,
            tooltip: 'Add Equipment',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search equipment...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterEquipment();
                  },
                ),
                const SizedBox(height: 16),
                
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Categories')),
                          DropdownMenuItem(value: 'hoist', child: Text('Hoist')),
                          DropdownMenuItem(value: 'wheelchair', child: Text('Wheelchair')),
                          DropdownMenuItem(value: 'bed', child: Text('Bed')),
                          DropdownMenuItem(value: 'chair', child: Text('Chair')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterCategory = value!;
                          });
                          _filterEquipment();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'safe', child: Text('Safe')),
                          DropdownMenuItem(value: 'unsafe', child: Text('Unsafe')),
                          DropdownMenuItem(value: 'service_due', child: Text('Service Due')),
                          DropdownMenuItem(value: 'expired_tests', child: Text('Expired Tests')),
                          DropdownMenuItem(value: 'faults', child: Text('Faults')),
                          DropdownMenuItem(value: 'high_risk', child: Text('High Risk')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                          _filterEquipment();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Equipment List
          Expanded(
            child: FutureBuilder<List<EquipmentRegisterAssessment>>(
              future: _equipmentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No equipment found'));
                } else {
                  return ListView.builder(
                    itemCount: _filteredEquipment.length,
                    itemBuilder: (context, index) {
                      final equipment = _filteredEquipment[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: _getEquipmentIcon(equipment.equipmentCategory),
                          title: Text(
                            equipment.equipmentName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${equipment.equipmentId}'),
                              Text('Category: ${equipment.equipmentCategoryDisplay}'),
                              Text('Status: ${equipment.equipmentStatus}'),
                              Text('Risk Level: ${equipment.riskLevel.toUpperCase()} ${equipment.riskLevelEmoji}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (equipment.lolerExpired)
                                const Icon(Icons.warning, color: Colors.red, size: 16),
                              if (equipment.serviceDue)
                                const Icon(Icons.build, color: Colors.orange, size: 16),
                              if (equipment.reportedFaults != 'none')
                                const Icon(Icons.report, color: Colors.yellow, size: 16),
                            ],
                          ),
                          onTap: () => _showEquipmentDetails(equipment),
                          onLongPress: () => _showEquipmentActions(equipment),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getEquipmentIcon(String category) {
    switch (category) {
      case 'hoist':
        return const Icon(Icons.settings, color: Colors.blue);
      case 'wheelchair':
        return const Icon(Icons.accessible, color: Colors.green);
      case 'bed':
        return const Icon(Icons.bed, color: Colors.orange);
      case 'chair':
        return const Icon(Icons.chair, color: Colors.brown);
      default:
        return const Icon(Icons.settings, color: Colors.grey);
    }
  }
}