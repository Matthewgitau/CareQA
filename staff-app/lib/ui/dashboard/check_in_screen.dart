import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/services/auth_service.dart';
import 'package:staff_app/services/firestore_service.dart';
import 'package:staff_app/models/shift.dart';
import 'package:staff_app/models/visit.dart';

class CheckInScreen extends StatefulWidget {
  final Shift shift;

  const CheckInScreen({super.key, required this.shift});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  Visit? _existingVisit;

  @override
  void initState() {
    super.initState();
    _loadExistingVisit();
  }

  Future<void> _loadExistingVisit() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUser();

    if (currentUser != null) {
      final visits = await firestoreService
          .getVisitsByCarer(currentUser.uid)
          .first;
      _existingVisit = visits.firstWhere(
        (visit) => visit.shiftId == widget.shift.id,
        orElse: () => Visit(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shiftId: widget.shift.id,
          carerId: currentUser.uid,
          notes: '',
        ),
      );
      setState(() {});
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _isLoading = true;
    });

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUser();

    if (currentUser != null) {
      try {
        final visit = Visit(
          id: _existingVisit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          shiftId: widget.shift.id,
          carerId: currentUser.uid,
          checkInTime: DateTime.now(),
          checkOutTime: _existingVisit?.checkOutTime,
          notes: _existingVisit?.notes ?? '',
        );

        if (_existingVisit != null) {
          await firestoreService.updateVisit(visit);
        } else {
          await firestoreService.addVisit(visit);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in successful!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkOut() async {
    setState(() {
      _isLoading = true;
    });

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUser();

    if (currentUser != null) {
      try {
        final visit = Visit(
          id: _existingVisit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          shiftId: widget.shift.id,
          carerId: currentUser.uid,
          checkInTime: _existingVisit?.checkInTime,
          checkOutTime: DateTime.now(),
          notes: _notesController.text.trim(),
        );

        if (_existingVisit != null) {
          await firestoreService.updateVisit(visit);
        } else {
          await firestoreService.addVisit(visit);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-out successful!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shift Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${widget.shift.date.toString().split(' ')[0]}'),
                    const SizedBox(height: 5),
                    Text(
                      'Time: ${widget.shift.startTime.hour.toString().padLeft(2, '0')}:${widget.shift.startTime.minute.toString().padLeft(2, '0')} - ${widget.shift.endTime.hour.toString().padLeft(2, '0')}:${widget.shift.endTime.minute.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(height: 5),
                    Text('Status: ${widget.shift.status}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Visit Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter any notes about this visit...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _existingVisit?.checkInTime != null ? null : _checkIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Check In',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _existingVisit?.checkInTime == null ? null : _checkOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Check Out',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            if (_existingVisit != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visit Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text('Check-in: ${_existingVisit?.checkInTime?.toIso8601String() ?? 'Not checked in'}'),
                      const SizedBox(height: 5),
                      Text('Check-out: ${_existingVisit?.checkOutTime?.toIso8601String() ?? 'Not checked out'}'),
                    ],
                  ),
                ),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}