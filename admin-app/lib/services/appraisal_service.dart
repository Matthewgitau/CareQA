import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appraisal.dart';

/// Service for managing staff appraisals in Supabase
class AppraisalService {
  final SupabaseClient _client;

  AppraisalService(this._client);

  /// Get all appraisals with employee and reviewer names
  Future<List<Appraisal>> getAllAppraisals() async {
    try {
      final response = await _client
          .from('appraisals')
          .select('''
            *,
            employee:employee_id!inner(name),
            reviewer:reviewer_id!inner(name)
          ''')
          .order('appraisal_date', ascending: false);

      return (response as List).map((json) {
        return Appraisal.fromJson({
          ...json,
          'employee_name': json['employee']?['name'],
          'reviewer_name': json['reviewer']?['name'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching all appraisals: $e');
      return [];
    }
  }

  /// Get appraisals for a specific employee
  Future<List<Appraisal>> getAppraisalsForEmployee(String employeeId) async {
    try {
      final response = await _client
          .from('appraisals')
          .select('''
            *,
            employee:employee_id!inner(name),
            reviewer:reviewer_id!inner(name)
          ''')
          .eq('employee_id', employeeId)
          .order('appraisal_date', ascending: false);

      return (response as List).map((json) {
        return Appraisal.fromJson({
          ...json,
          'employee_name': json['employee']?['name'],
          'reviewer_name': json['reviewer']?['name'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching appraisals for employee: $e');
      return [];
    }
  }

  /// Get a single appraisal by ID
  Future<Appraisal?> getAppraisalById(String id) async {
    try {
      final response = await _client
          .from('appraisals')
          .select('''
            *,
            employee:employee_id!inner(name),
            reviewer:reviewer_id!inner(name)
          ''')
          .eq('id', id)
          .single();

      return Appraisal.fromJson({
        ...response,
        'employee_name': response['employee']?['name'],
        'reviewer_name': response['reviewer']?['name'],
      });
    } catch (e) {
      print('Error fetching appraisal: $e');
      return null;
    }
  }

  /// Create a new appraisal
  Future<Appraisal?> createAppraisal(Appraisal appraisal) async {
    try {
      final data = appraisal.toJson();
      data.remove('id'); // Let DB generate UUID
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('appraisals')
          .insert(data)
          .select()
          .single();

      return Appraisal.fromJson(response);
    } catch (e) {
      print('Error creating appraisal: $e');
      rethrow;
    }
  }

  /// Update an existing appraisal
  Future<Appraisal?> updateAppraisal(Appraisal appraisal) async {
    try {
      final data = appraisal.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('appraisals')
          .update(data)
          .eq('id', appraisal.id)
          .select()
          .single();

      return Appraisal.fromJson(response);
    } catch (e) {
      print('Error updating appraisal: $e');
      rethrow;
    }
  }

  /// Delete an appraisal
  Future<void> deleteAppraisal(String id) async {
    try {
      await _client.from('appraisals').delete().eq('id', id);
    } catch (e) {
      print('Error deleting appraisal: $e');
      rethrow;
    }
  }

  /// Check if an employee is eligible for an appraisal
  /// Employee must have been employed for at least 365 days
  /// and not have had an appraisal in the last 12 months
  Future<Map<String, dynamic>> checkEligibility(String employeeId) async {
    try {
      // Get employee profile to check created_at
      final profile = await _client
          .from('profiles')
          .select('id, created_at, full_name, name, email')
          .eq('id', employeeId)
          .single();

      final createdAt = profile['created_at'] != null
          ? DateTime.parse(profile['created_at'])
          : DateTime.now();
      final daysEmployed = DateTime.now().difference(createdAt).inDays;
      final meetsTenureRequirement = daysEmployed >= 365;

      // Get most recent appraisal
      final recentAppraisals = await _client
          .from('appraisals')
          .select('appraisal_date, next_appraisal_date')
          .eq('employee_id', employeeId)
          .order('appraisal_date', ascending: false)
          .limit(1);

      bool hasRecentAppraisal = false;
      DateTime? lastAppraisalDate;
      DateTime? nextAppraisalDate;

      if (recentAppraisals.isNotEmpty) {
        lastAppraisalDate = DateTime.parse(recentAppraisals[0]['appraisal_date']);
        nextAppraisalDate = recentAppraisals[0]['next_appraisal_date'] != null
            ? DateTime.parse(recentAppraisals[0]['next_appraisal_date'])
            : null;

        // Check if last appraisal was within 12 months
        final monthsSinceLastAppraisal = DateTime.now().difference(lastAppraisalDate).inDays / 30;
        hasRecentAppraisal = monthsSinceLastAppraisal < 12;
      }

      final isEligible = meetsTenureRequirement && !hasRecentAppraisal;

      return {
        'isEligible': isEligible,
        'employeeName': profile['full_name'] ?? profile['name'] ?? profile['email'] ?? 'Unknown',
        'daysEmployed': daysEmployed,
        'meetsTenureRequirement': meetsTenureRequirement,
        'hasRecentAppraisal': hasRecentAppraisal,
        'lastAppraisalDate': lastAppraisalDate,
        'nextAppraisalDate': nextAppraisalDate,
        'reason': !meetsTenureRequirement
            ? 'Employee has only been employed for $daysEmployed days. 365 days required.'
            : hasRecentAppraisal
                ? 'Employee already had an appraisal within the last 12 months.'
                : null,
      };
    } catch (e) {
      print('Error checking eligibility: $e');
      return {
        'isEligible': false,
        'error': e.toString(),
      };
    }
  }

  /// Get all employees (carers only) - matches drivers_screen pattern
  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final data = await _client
          .from('carers')
          .select('id, name, employee_number, job_role, phone, date_of_birth');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  /// Get all reviewers (profiles with admin role)
  Future<List<Map<String, dynamic>>> getAllReviewers() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, name, email, role')
          .eq('role', 'admin')
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reviewers: $e');
      return [];
    }
  }

  /// Get all profiles (fallback for admins)
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, name, email, role, created_at')
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching profiles: $e');
      return [];
    }
  }

  /// Get appraisal matrix data for all employees
  Future<List<Map<String, dynamic>>> getAppraisalMatrix() async {
    try {
      // Get all carers
      final employees = await getAllEmployees();
      final matrixData = <Map<String, dynamic>>[];

      for (final emp in employees) {
        final empId = emp['id'] as String;
        final empName = emp['name'] ?? emp['email'] ?? 'Unknown';
        final createdAt = emp['created_at'] != null
            ? DateTime.parse(emp['created_at'])
            : DateTime.now();
        final daysEmployed = DateTime.now().difference(createdAt).inDays;
        final meetsTenure = daysEmployed >= 365;

        // Get most recent appraisal
        final recentAppraisals = await _client
            .from('appraisals')
            .select('appraisal_date, next_appraisal_date, overall_rating, status')
            .eq('employee_id', empId)
            .order('appraisal_date', ascending: false)
            .limit(1);

        DateTime? lastAppraisalDate;
        DateTime? nextAppraisalDate;
        int? overallRating;
        String? status;

        if (recentAppraisals.isNotEmpty) {
          lastAppraisalDate = DateTime.parse(recentAppraisals[0]['appraisal_date']);
          nextAppraisalDate = recentAppraisals[0]['next_appraisal_date'] != null
              ? DateTime.parse(recentAppraisals[0]['next_appraisal_date'])
              : null;
          overallRating = recentAppraisals[0]['overall_rating'];
          status = recentAppraisals[0]['status'];
        }

        // Determine matrix status
        String matrixStatus;
        if (!meetsTenure) {
          matrixStatus = 'not_eligible';
        } else if (lastAppraisalDate == null) {
          matrixStatus = 'eligible';
        } else if (nextAppraisalDate != null && nextAppraisalDate.isBefore(DateTime.now())) {
          matrixStatus = 'overdue';
        } else if (nextAppraisalDate != null &&
            nextAppraisalDate.difference(DateTime.now()).inDays <= 30) {
          matrixStatus = 'due_soon';
        } else {
          matrixStatus = 'completed';
        }

        matrixData.add({
          'employeeId': empId,
          'employeeName': empName,
          'daysEmployed': daysEmployed,
          'meetsTenure': meetsTenure,
          'lastAppraisalDate': lastAppraisalDate,
          'nextAppraisalDate': nextAppraisalDate,
          'overallRating': overallRating,
          'status': status,
          'matrixStatus': matrixStatus,
          'daysSinceLastAppraisal': lastAppraisalDate != null
              ? DateTime.now().difference(lastAppraisalDate).inDays
              : null,
          'daysUntilNextAppraisal': nextAppraisalDate != null
              ? nextAppraisalDate.difference(DateTime.now()).inDays
              : null,
        });
      }

      return matrixData;
    } catch (e) {
      print('Error fetching appraisal matrix: $e');
      return [];
    }
  }
}