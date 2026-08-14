import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/services/auth_service.dart';
import 'package:staff_app/services/firestore_service.dart';
import 'package:staff_app/models/shift.dart';
import 'package:staff_app/models/visit.dart';
import 'check_in_screen.dart';

class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final currentUser = authService.getCurrentUser();

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view your shifts'));
    }

    return StreamBuilder<List<Shift>>(
      stream: firestoreService.getShiftsForCurrentUser(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final shifts = snapshot.data ?? [];

        if (shifts.isEmpty) {
          return const Center(
            child: Text(
              'No shifts assigned yet',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic can be added here
          },
          child: ListView.builder(
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final shift = shifts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Shift ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${shift.date.toString().split(' ')[0]}'),
                      Text('Time: ${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')} - ${shift.endTime.hour.toString().padLeft(2, '0')}:${shift.endTime.minute.toString().padLeft(2, '0')}'),
                      Text('Status: ${shift.status}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckInScreen(shift: shift),
                        ),
                      );
                    },
                    child: const Text('Check In'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}