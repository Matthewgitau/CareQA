import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/services/supabase_auth_service.dart';
import 'package:staff_app/services/firestore_service.dart';
import 'package:staff_app/models/shift.dart';
import 'package:staff_app/models/visit.dart';
import '../notifications/notification_bell.dart';
import 'shifts_screen.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<SupabaseAuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareQA Staff Dashboard'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: currentUser != null
          ? Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Welcome to CareQA Staff',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ShiftsScreen(),
                ),
              ],
            )
          : const Center(
              child: Text('Please log in to view your dashboard'),
            ),
    );
  }
}