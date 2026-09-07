import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PayrollRatesScreen extends StatefulWidget {
  const PayrollRatesScreen({super.key});
  @override
  State<PayrollRatesScreen> createState() => _PayrollRatesScreenState();
}

class _PayrollRatesScreenState extends State<PayrollRatesScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _staff = [];
  Map<String, double> _rates = {};
  Map<String, double> _editingRates = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profiles = await _client.from('profiles').select('id, full_name, email, role').order('full_name');
      final staff = (profiles as List).cast<Map<String, dynamic>>();
      final rates = <String, double>{};
      try {
        final ph = await _client.from('payroll_history').select('staff_id, hourly_rate').order('period_end', ascending: false);
        for (final p in (ph as List).cast<Map<String, dynamic>>()) {
          final sid = p['staff_id'] as String?;
          final rate = (p['hourly_rate'] as num?)?.toDouble();
          if (sid != null && rate != null && !rates.containsKey(sid)) rates[sid] = rate;
        }
      } catch (_) {}
      if (mounted) setState(() { _staff = staff; _rates = rates; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _saveRate(String staffId, String staffName, double rate) async {
    try {
      await _client.from('payroll_history').insert({
        'staff_id': staffId, 'staff_name': staffName, 'period_start': '2026-01-01', 'period_end': '2099-12-31',
        'hourly_rate': rate, 'regular_hours': 0, 'regular_pay': 0, 'overtime_hours': 0,
        'overtime_pay': 0, 'holiday_pay': 0, 'sick_pay': 0, 'bonus_pay': 0, 'deductions': 0,
        'status': 'draft', 'created_at': DateTime.now().toIso8601String(),
      });
      setState(() { _rates[staffId] = rate; _editingRates.remove(staffId); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('\$staffName rate set to \u00a3${rate.toStringAsFixed(2)}/hr'),
        backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: \$e'), backgroundColor: Colors.red));
    }
  }
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Carer Pay Rates'), backgroundColor: Color(0xFF1565C0), foregroundColor: Colors.white),
    body: _loading ? Center(child: CircularProgressIndicator()) : _staff.isEmpty ? Center(child: Text('No staff found')) :
    ListView.builder(padding: EdgeInsets.all(12), itemCount: _staff.length, itemBuilder: (_, i) {
      final s = _staff[i]; final sid = s['id'] as String;
      final name = (s['full_name'] ?? s['name'] ?? s['email'] ?? 'Staff').toString();
      final email = (s['email'] ?? '').toString(); final role = (s['role'] ?? '').toString();
      final cr = _rates[sid]; final ed = _editingRates.containsKey(sid);
      final ec = TextEditingController(text: ed ? _editingRates[sid]!.toStringAsFixed(2) : (cr?.toStringAsFixed(2) ?? '11.44'));
      return Card(margin: EdgeInsets.only(bottom: 8), child: ListTile(
        leading: CircleAvatar(backgroundColor: role=='carer'?Colors.green.shade100:Colors.blue.shade100,
          child: Icon(role=='carer'?Icons.person:Icons.admin_panel_settings, size: 20, color: role=='carer'?Colors.green:Colors.blue)),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('\$role \u2022 \$email', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: SizedBox(width: 140, child: Row(mainAxisSize: MainAxisSize.min, children: [
          cr != null && !ed ? GestureDetector(onTap: () => setState(() => _editingRates[sid] = cr),
            child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
              child: Text('\u00a3${cr.toStringAsFixed(2)}/hr', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13)))) :
            SizedBox(width: 80, height: 36, child: TextField(controller: ec, keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 6), border: OutlineInputBorder(), hintText: '11.44'),
              style: TextStyle(fontSize: 13), onSubmitted: (v) { final r = double.tryParse(v.trim()); if (r!=null && r>0) _saveRate(sid, name, r); })),
          if (ed) IconButton(icon: Icon(Icons.save, size: 20, color: Colors.blue), padding: EdgeInsets.zero, constraints: BoxConstraints(),
            onPressed: () { final r = double.tryParse(ec.text.trim()); if (r!=null && r>0) _saveRate(sid, name, r); }),
        ])),
      ));
    }));
}