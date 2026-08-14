import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/food_fluid_service.dart';

class FoodFluidScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  const FoodFluidScreen({super.key, required this.serviceUserId, required this.serviceUserName});
  @override
  State<FoodFluidScreen> createState() => _FoodFluidScreenState();
}

class _FoodFluidScreenState extends State<FoodFluidScreen> {
  final _service = FoodFluidService(Supabase.instance.client);
  List<dynamic> _charts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _service.getChartSummariesForServiceUser(widget.serviceUserId);
      setState(() { _charts = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food & Fluid — ${widget.serviceUserName}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New chart coming soon'))),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _charts.isEmpty
              ? const Center(child: Text('No food & fluid charts found'))
              : ListView.builder(
                  itemCount: _charts.length,
                  itemBuilder: (_, i) {
                    final c = _charts[i];
                    return ListTile(
                      title: Text('Chart: ${c.chartDate.toString().split(' ').first}'),
                      subtitle: Text('Warning: ${c.warningTriggered ? 'Yes' : 'No'} — Days since bowel: ${c.daysSinceLastBowel}'),
                    );
                  },
                ),
    );
  }
}