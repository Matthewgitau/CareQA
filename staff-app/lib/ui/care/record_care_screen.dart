import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/shift.dart';
import 'package:staff_app/ui/daily/repositioning_form.dart';
import 'package:staff_app/ui/daily/food_fluid_form.dart';
import 'package:staff_app/ui/daily/bowel_bladder_form.dart';
import 'package:staff_app/ui/daily/sleep_form.dart';
import 'package:staff_app/ui/care/daily_note_form.dart';
import 'package:staff_app/ui/care/body_map_form.dart';
import 'package:staff_app/ui/medication/mar_chart_screen.dart';

/// Hub screen launched from a shift/route-call detail.
/// The carer picks which care record to complete for this visit.
class RecordCareScreen extends StatelessWidget {
  final Shift shift;
  final String carerId;

  const RecordCareScreen({super.key, required this.shift, required this.carerId});

  @override
  Widget build(BuildContext context) {
    final suName = shift.serviceUserName ?? 'Service User';
    final suId = shift.serviceUserId ?? '';
    final carerName = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text('Record Care – $suName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _tile(context, 'Daily Notes', Icons.edit_note, Colors.indigo,
                () => _open(context, DailyNoteForm(
                      serviceUserId: suId,
                      serviceUserName: suName,
                      carerId: carerId,
                    ))),
            _tile(context, 'Food & Fluid', Icons.restaurant, Colors.orange,
                () => _open(context, FoodFluidForm(
                      serviceUserId: suId,
                      serviceUserName: suName,
                    ))),
            _tile(context, 'Bowel & Bladder', Icons.wc, Colors.brown,
                () => _open(context, BowelBladderForm(
                      serviceUserId: suId,
                      serviceUserName: suName,
                    ))),
            _tile(context, 'Repositioning', Icons.airline_seat_flat, Colors.teal,
                () => _open(context, RepositioningForm(
                      serviceUserId: suId,
                      carerId: carerId,
                    ))),
            _tile(context, 'Sleep Check', Icons.bedtime, Colors.deepPurple,
                () => _open(context, SleepForm(
                      serviceUserId: suId,
                      carerId: carerId,
                    ))),
            _tile(context, 'Body Map', Icons.accessibility_new, Colors.red,
                () => _open(context, BodyMapForm(
                      serviceUserId: suId,
                      carerId: carerId,
                    ))),
            _tile(context, 'MAR Chart', Icons.medication, Colors.pink,
                () => _open(context, MarChartScreen(
                      serviceUserId: suId,
                      serviceUserName: suName,
                      carerId: carerId,
                      carerName: carerName,
                    ))),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext ctx, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext ctx, Widget form) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => form));
  }
}