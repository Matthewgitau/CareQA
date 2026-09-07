import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/models/carer.dart';
import 'package:admin_app/services/database_service.dart';
import 'carer_form_screen.dart';
import 'carer_invite_screen.dart';

class CarerListScreen extends StatelessWidget {
  const CarerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CarerInviteScreen()),
              );
            },
            tooltip: 'Invite Carer',
          ),
        ],
      ),
      body: FutureBuilder<List<Carer>>(
        future: databaseService.getCarers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final carers = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh logic can be added here
            },
            child: ListView.builder(
              itemCount: carers.length,
              itemBuilder: (context, index) {
                final carer = carers[index];
                final status = carer.inviteStatus ?? (carer.isActive ? 'active' : 'inactive');
                final statusColor = status == 'active'
                    ? Colors.green
                    : status == 'inactive'
                        ? Colors.red
                        : Colors.orange;
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(carer.name ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(carer.email ?? ''),
                        Text('Role: ${carer.jobRole ?? 'carer'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(
                            status.toUpperCase(),
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: statusColor.withOpacity(0.1),
                          labelStyle: TextStyle(color: statusColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CarerFormScreen(carer: carer),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteDialog(context, carer);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CarerFormScreen(),
            ),
          );
        },
        tooltip: 'Add Carer',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Carer carer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Carer'),
        content: Text('Are you sure you want to delete ${carer.name ?? 'this carer'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final databaseService =
                  Provider.of<DatabaseService>(context, listen: false);
              databaseService.deleteCarer(carer.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Carer deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}