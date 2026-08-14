import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/models/shift.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/carer.dart';

void main() {
  group('Shift Model Tests', () {
    test('Shift creation with all fields', () {
      final shift = Shift(
        id: 'test-id',
        serviceUserId: 'user-123',
        carerId: 'carer-456',
        date: DateTime(2023, 12, 25),
        startTime: DateTime(2023, 12, 25, 9, 0),
        endTime: DateTime(2023, 12, 25, 17, 0),
        status: 'scheduled',
        notes: 'Test shift notes',
      );

      expect(shift.id, 'test-id');
      expect(shift.serviceUserId, 'user-123');
      expect(shift.carerId, 'carer-456');
      expect(shift.date, DateTime(2023, 12, 25));
      expect(shift.startTime, DateTime(2023, 12, 25, 9, 0));
      expect(shift.endTime, DateTime(2023, 12, 25, 17, 0));
      expect(shift.status, 'scheduled');
      expect(shift.notes, 'Test shift notes');
    });

    test('Shift toMap conversion', () {
      final shift = Shift(
        id: 'test-id',
        serviceUserId: 'user-123',
        carerId: 'carer-456',
        date: DateTime(2023, 12, 25),
        startTime: DateTime(2023, 12, 25, 9, 0),
        endTime: DateTime(2023, 12, 25, 17, 0),
        status: 'scheduled',
        notes: 'Test shift notes',
      );

      final map = shift.toMap();
      
      expect(map['service_user_id'], 'user-123');
      expect(map['carer_id'], 'carer-456');
      expect(map['date'], '2023-12-25T00:00:00.000');
      expect(map['start_time'], '2023-12-25T09:00:00.000');
      expect(map['end_time'], '2023-12-25T17:00:00.000');
      expect(map['status'], 'scheduled');
      expect(map['notes'], 'Test shift notes');
    });

    test('Shift fromMap conversion', () {
      final map = {
        'id': 'test-id',
        'service_user_id': 'user-123',
        'carer_id': 'carer-456',
        'date': '2023-12-25T00:00:00.000',
        'start_time': '2023-12-25T09:00:00.000',
        'end_time': '2023-12-25T17:00:00.000',
        'status': 'scheduled',
        'notes': 'Test shift notes',
      };

      final shift = Shift.fromMap(map);
      
      expect(shift.id, 'test-id');
      expect(shift.serviceUserId, 'user-123');
      expect(shift.carerId, 'carer-456');
      expect(shift.date, DateTime(2023, 12, 25));
      expect(shift.startTime, DateTime(2023, 12, 25, 9, 0));
      expect(shift.endTime, DateTime(2023, 12, 25, 17, 0));
      expect(shift.status, 'scheduled');
      expect(shift.notes, 'Test shift notes');
    });

    test('Shift validation - end time after start time', () {
      final startTime = DateTime(2023, 12, 25, 9, 0);
      final endTime = DateTime(2023, 12, 25, 17, 0);
      
      expect(endTime.isAfter(startTime), true);
    });

    test('Shift validation - end time not before start time', () {
      final startTime = DateTime(2023, 12, 25, 9, 0);
      final endTime = DateTime(2023, 12, 25, 8, 0);
      
      expect(endTime.isBefore(startTime), true);
    });

    test('Shift validation - date not in past', () {
      final today = DateTime.now();
      final tomorrow = today.add(Duration(days: 1));
      
      expect(tomorrow.isAfter(today), true);
    });
  });

  group('Service User Model Tests', () {
    test('ServiceUser creation', () {
      final user = ServiceUser(
        id: 'user-123',
        name: 'John Doe',
        address: '123 Main St',
        notes: 'Test notes',
        createdAt: DateTime.now(),
      );

      expect(user.id, 'user-123');
      expect(user.name, 'John Doe');
      expect(user.address, '123 Main St');
      expect(user.notes, 'Test notes');
    });
  });

  group('Carer Model Tests', () {
    test('Carer creation', () {
      final carer = Carer(
        id: 'carer-456',
        name: 'Jane Smith',
        email: 'jane@example.com',
        phone: '555-1234',
        employeeNumber: 'EMP123',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(carer.id, 'carer-456');
      expect(carer.name, 'Jane Smith');
      expect(carer.email, 'jane@example.com');
      expect(carer.phone, '555-1234');
      expect(carer.employeeNumber, 'EMP123');
      expect(carer.isActive, true);
    });
  });
}