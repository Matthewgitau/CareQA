import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/models/sleep_chart.dart';

void main() {
  group('SleepChart', () {
    test('should create SleepChart from JSON', () {
      final json = {
        'id': 'test-id',
        'service_user_id': 'user-123',
        'chart_date': '2024-03-21T00:00:00.000Z',
        'bedtime_time': '22:30',
        'bedtime_routine': 'Read book, brush teeth',
        'overnight_entries': [
          {
            'time': '2024-03-21T22:30:00.000Z',
            'status': 'Asleep',
            'notes': 'Fell asleep quickly'
          },
          {
            'time': '2024-03-22T02:00:00.000Z',
            'status': 'Up-toilet',
            'notes': 'Used bathroom'
          }
        ],
        'sleep_quality': 'Good',
        'morning_notes': 'Woke up refreshed',
        'created_by': 'carer-123',
        'created_at': '2024-03-21T10:00:00.000Z',
        'updated_by': 'admin-123',
        'updated_at': '2024-03-21T12:00:00.000Z',
        'has_distressing_observations': false,
      };

      final chart = SleepChart.fromJson(json);

      expect(chart.id, 'test-id');
      expect(chart.serviceUserId, 'user-123');
      expect(chart.chartDate.year, 2024);
      expect(chart.bedtimeTime?.hour, 22);
      expect(chart.bedtimeTime?.minute, 30);
      expect(chart.bedtimeRoutine, 'Read book, brush teeth');
      expect(chart.overnightEntries.length, 2);
      expect(chart.overnightEntries[0].status, 'Asleep');
      expect(chart.overnightEntries[1].status, 'Up-toilet');
      expect(chart.sleepQuality, 'Good');
      expect(chart.morningNotes, 'Woke up refreshed');
      expect(chart.hasDistressingObservations, false);
    });

    test('should convert SleepChart to JSON', () {
      final chart = SleepChart(
        id: 'test-id',
        serviceUserId: 'user-123',
        chartDate: DateTime(2024, 3, 21),
        bedtimeTime: TimeOfDay(hour: 22, minute: 30),
        bedtimeRoutine: 'Read book, brush teeth',
        overnightEntries: [
          OvernightObservation(
            time: DateTime(2024, 3, 21, 22, 30),
            status: 'Asleep',
            notes: 'Fell asleep quickly',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 2, 0),
            status: 'Up-toilet',
            notes: 'Used bathroom',
          ),
        ],
        sleepQuality: 'Good',
        morningNotes: 'Woke up refreshed',
        hasDistressingObservations: false,
      );

      final json = chart.toJson();

      expect(json['service_user_id'], 'user-123');
      expect(json['bedtime_time'], '22:30');
      expect(json['bedtime_routine'], 'Read book, brush teeth');
      expect((json['overnight_entries'] as List).length, 2);
      expect(json['sleep_quality'], 'Good');
      expect(json['morning_notes'], 'Woke up refreshed');
      expect(json['has_distressing_observations'], false);
    });

    test('should detect distressing observations', () {
      final chartWithDistressing = SleepChart(
        serviceUserId: 'user-123',
        chartDate: DateTime(2024, 3, 21),
        overnightEntries: [
          OvernightObservation(
            time: DateTime(2024, 3, 21, 22, 30),
            status: 'Asleep',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 2, 0),
            status: 'Distressed',
          ),
        ],
      );

      final chartWithoutDistressing = SleepChart(
        serviceUserId: 'user-123',
        chartDate: DateTime(2024, 3, 21),
        overnightEntries: [
          OvernightObservation(
            time: DateTime(2024, 3, 21, 22, 30),
            status: 'Asleep',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 2, 0),
            status: 'Awake-settled',
          ),
        ],
      );

      expect(chartWithDistressing.hasAnyDistressingObservations(), true);
      expect(chartWithoutDistressing.hasAnyDistressingObservations(), false);
    });

    test('should get distressing observations', () {
      final chart = SleepChart(
        serviceUserId: 'user-123',
        chartDate: DateTime(2024, 3, 21),
        overnightEntries: [
          OvernightObservation(
            time: DateTime(2024, 3, 21, 22, 30),
            status: 'Asleep',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 2, 0),
            status: 'Distressed',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 3, 0),
            status: 'Asleep',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 4, 0),
            status: 'Pain reported',
          ),
        ],
      );

      final distressingObservations = chart.getDistressingObservations();

      expect(distressingObservations.length, 2);
      expect(distressingObservations[0].status, 'Distressed');
      expect(distressingObservations[1].status, 'Pain reported');
    });

    test('should get observation statistics', () {
      final chart = SleepChart(
        serviceUserId: 'user-123',
        chartDate: DateTime(2024, 3, 21),
        overnightEntries: [
          OvernightObservation(
            time: DateTime(2024, 3, 21, 22, 30),
            status: 'Asleep',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 2, 0),
            status: 'Asleep',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 3, 0),
            status: 'Up-toilet',
          ),
          OvernightObservation(
            time: DateTime(2024, 3, 22, 4, 0),
            status: 'Distressed',
          ),
        ],
      );

      final stats = chart.getObservationStatistics();

      expect(stats['Asleep'], 2);
      expect(stats['Up-toilet'], 1);
      expect(stats['Distressed'], 1);
      expect(stats['Awake-settled'], null);
    });
  });

  group('OvernightObservation', () {
    test('should create OvernightObservation from JSON', () {
      final json = {
        'time': '2024-03-21T22:30:00.000Z',
        'status': 'Asleep',
        'notes': 'Fell asleep quickly',
      };

      final observation = OvernightObservation.fromJson(json);

      expect(observation.time.year, 2024);
      expect(observation.status, 'Asleep');
      expect(observation.notes, 'Fell asleep quickly');
    });

    test('should convert OvernightObservation to JSON', () {
      final observation = OvernightObservation(
        time: DateTime(2024, 3, 21, 22, 30),
        status: 'Asleep',
        notes: 'Fell asleep quickly',
      );

      final json = observation.toJson();

      expect(json['time'], '2024-03-21T22:30:00.000Z');
      expect(json['status'], 'Asleep');
      expect(json['notes'], 'Fell asleep quickly');
    });

    test('should get correct status colors', () {
      final asleepObservation = OvernightObservation(
        time: DateTime(2024, 3, 21, 22, 30),
        status: 'Asleep',
      );
      final distressedObservation = OvernightObservation(
        time: DateTime(2024, 3, 22, 2, 0),
        status: 'Distressed',
      );

      expect(asleepObservation.getStatusColor(), Colors.green);
      expect(distressedObservation.getStatusColor(), Colors.red);
    });

    test('should get correct status descriptions', () {
      final asleepObservation = OvernightObservation(
        time: DateTime(2024, 3, 21, 22, 30),
        status: 'Asleep',
      );
      final distressedObservation = OvernightObservation(
        time: DateTime(2024, 3, 22, 2, 0),
        status: 'Distressed',
      );

      expect(asleepObservation.getStatusDescription(), 'Resting peacefully');
      expect(distressedObservation.getStatusDescription(), 'In distress');
    });
  });

  group('SleepAuditLog', () {
    test('should create SleepAuditLog from JSON', () {
      final json = {
        'id': 'audit-123',
        'chart_id': 'chart-123',
        'edited_by': 'user-123',
        'previous_data': {
          'sleep_quality': 'Good',
          'morning_notes': 'Woke up refreshed',
        },
        'new_data': {
          'sleep_quality': 'Fair',
          'morning_notes': 'Woke up tired',
        },
        'edited_at': '2024-03-21T12:00:00.000Z',
        'profiles': {
          'full_name': 'John Doe',
        },
      };

      final auditLog = SleepAuditLog.fromJson(json);

      expect(auditLog.id, 'audit-123');
      expect(auditLog.chartId, 'chart-123');
      expect(auditLog.editedBy, 'user-123');
      expect(auditLog.previousData['sleep_quality'], 'Good');
      expect(auditLog.newData['sleep_quality'], 'Fair');
      expect(auditLog.editedAt.year, 2024);
      expect(auditLog.editedByName, 'John Doe');
    });
  });

  group('SleepChartSummary', () {
    test('should create SleepChartSummary from JSON', () {
      final json = {
        'id': 'chart-123',
        'service_user_id': 'user-123',
        'chart_date': '2024-03-21T00:00:00.000Z',
        'sleep_quality': 'Good',
        'overnight_entry_count': 5,
        'has_distressing_observations': false,
        'created_by': 'carer-123',
        'created_at': '2024-03-21T10:00:00.000Z',
        'updated_by': 'admin-123',
        'updated_at': '2024-03-21T12:00:00.000Z',
      };

      final summary = SleepChartSummary.fromJson(json);

      expect(summary.id, 'chart-123');
      expect(summary.serviceUserId, 'user-123');
      expect(summary.chartDate.year, 2024);
      expect(summary.sleepQuality, 'Good');
      expect(summary.overnightEntryCount, 5);
      expect(summary.hasDistressingObservations, false);
      expect(summary.createdBy, 'carer-123');
      expect(summary.updatedBy, 'admin-123');
    });
  });
}