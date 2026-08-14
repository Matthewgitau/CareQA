import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/services/database_service.dart';
import 'service_user_form_screen.dart';

class ServiceUserListScreen extends StatefulWidget {
  const ServiceUserListScreen({super.key});
  @override
  State<ServiceUserListScreen> createState() => _ServiceUserListScreenState();
}

class _ServiceUserListScreenState extends State<ServiceUserListScreen> {
  List<ServiceUser> _serviceUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<DatabaseService>();
    final data = await db.getServiceUsers();
    setState(() { _serviceUsers = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _serviceUsers.length,
                itemBuilder: (context, index) {
                  final serviceUser = _serviceUsers[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(serviceUser.name),
                      subtitle: Text(serviceUser.address),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    ServiceUserFormScreen(serviceUser: serviceUser))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteDialog(context, serviceUser),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ServiceUserFormScreen())),
        tooltip: 'Add Service User',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ServiceUser serviceUser) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service User'),
        content: Text('Are you sure you want to delete ${serviceUser.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final db = context.read<DatabaseService>();
              await db.deleteServiceUser(serviceUser.id);
              if (context.mounted) Navigator.pop(context);
              _load();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}