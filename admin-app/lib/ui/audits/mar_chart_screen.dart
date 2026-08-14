import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/supabase_auth_service.dart';

class MarChartScreen extends StatefulWidget {
  const MarChartScreen({super.key});
  @override
  State<MarChartScreen> createState() => _MarChartScreenState();
}

class _MarChartScreenState extends State<MarChartScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('mar_audits')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      setState(() { _items = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAR Chart')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No records found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(_items[i]['service_user_name']?.toString() ?? 'Record ${i + 1}'),
                      subtitle: Text(_items[i]['reference']?.toString() ?? ''),
                      trailing: Text(_items[i]['date']?.toString() ?? ''),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}