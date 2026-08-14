import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';

class SupplierService {
  final SupabaseClient _client;

  SupplierService(this._client);

  // Get all active suppliers
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _client
          .from('supplier_register')
          .select()
          .eq('supplier_status', 'active')
          .order('supplier_name', ascending: true);

      return (response as List)
          .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load suppliers: $e');
    }
  }

  // Get single supplier by ID
  Future<Supplier> getSupplier(String id) async {
    try {
      final response = await _client
          .from('supplier_register')
          .select()
          .eq('id', id)
          .single();

      return Supplier.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load supplier: $e');
    }
  }

  // Create new supplier
  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = supplier.toJson();
      data['created_by'] = user.id;
      data['updated_by'] = user.id;

      final response = await _client
          .from('supplier_register')
          .insert(data)
          .select()
          .single();

      return Supplier.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create supplier: $e');
    }
  }

  // Update supplier
  Future<Supplier> updateSupplier(String id, Map<String, dynamic> updates) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      updates['updated_by'] = user.id;

      final response = await _client
          .from('supplier_register')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Supplier.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update supplier: $e');
    }
  }

  // Soft delete (set inactive)
  Future<void> deleteSupplier(String id) async {
    try {
      await _client
          .from('supplier_register')
          .update({'supplier_status': 'inactive'})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete supplier: $e');
    }
  }

  // Get suppliers by type
  Future<List<Supplier>> getSuppliersByType(String type) async {
    try {
      final response = await _client
          .from('supplier_register')
          .select()
          .eq('supplier_type', type)
          .eq('supplier_status', 'active')
          .order('supplier_name', ascending: true);

      return (response as List)
          .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load suppliers by type: $e');
    }
  }

  // Get suppliers with expiring insurance
  Future<List<Supplier>> getExpiringInsurance(int days) async {
    try {
      final expiryDate = DateTime.now().add(Duration(days: days)).toIso8601String();

      final response = await _client
          .from('supplier_register')
          .select()
          .lte('public_liability_expiry', expiryDate)
          .eq('supplier_status', 'active')
          .order('public_liability_expiry', ascending: true);

      return (response as List)
          .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load expiring insurance: $e');
    }
  }

  // Get compliance status summary
  Future<Map<String, int>> getComplianceStatus() async {
    try {
      final response = await _client
          .from('supplier_register')
          .select('compliance_status')
          .eq('supplier_status', 'active');

      final suppliers = response as List;
      final summary = <String, int>{
        'compliant': 0,
        'non_compliant': 0,
        'pending': 0,
        'needs_review': 0,
      };

      for (final supplier in suppliers) {
        final status = supplier['compliance_status'] as String? ?? 'pending';
        summary[status] = (summary[status] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      throw Exception('Failed to load compliance status: $e');
    }
  }

  // Get contracts expiring soon
  Future<List<Supplier>> getContractExpiring(int days) async {
    try {
      final expiryDate = DateTime.now().add(Duration(days: days)).toIso8601String();

      final response = await _client
          .from('supplier_register')
          .select()
          .lte('contract_end_date', expiryDate)
          .eq('supplier_status', 'active')
          .order('contract_end_date', ascending: true);

      return (response as List)
          .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load expiring contracts: $e');
    }
  }

  // Validate supplier compliance
  Future<Map<String, dynamic>> validateSupplierCompliance(String supplierId) async {
    try {
      final supplier = await getSupplier(supplierId);
      final issues = <String>[];

      // Check insurance expiry
      final now = DateTime.now();
      if (supplier.publicLiabilityExpiry != null && supplier.publicLiabilityExpiry!.isBefore(now)) {
        issues.add('Public liability insurance expired');
      }
      if (supplier.employersLiabilityExpiry != null && supplier.employersLiabilityExpiry!.isBefore(now)) {
        issues.add('Employers liability insurance expired');
      }
      if (supplier.professionalIndemnityExpiry != null && supplier.professionalIndemnityExpiry!.isBefore(now)) {
        issues.add('Professional indemnity insurance expired');
      }

      // Check required documents
      if (supplier.dataSharingAgreementUrl == null) {
        issues.add('Data sharing agreement missing');
      }
      if (supplier.healthSafetyPolicyUrl == null) {
        issues.add('Health and safety policy missing');
      }

      // Check contract expiry
      if (supplier.contractEndDate != null && supplier.contractEndDate!.isBefore(now)) {
        issues.add('Contract has expired');
      }

      return {
        'isCompliant': issues.isEmpty,
        'issues': issues,
        'supplier': supplier,
      };
    } catch (e) {
      throw Exception('Failed to validate supplier compliance: $e');
    }
  }

  // Search suppliers by name or registration number
  Future<List<Supplier>> searchSuppliers(String query) async {
    try {
      final response = await _client
          .from('supplier_register')
          .select()
          .or('supplier_name.ilike.%$query%,company_registration_number.ilike.%$query%')
          .eq('supplier_status', 'active')
          .order('supplier_name', ascending: true);

      return (response as List)
          .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search suppliers: $e');
    }
  }

  // Get supplier types
  List<String> getSupplierTypes() {
    return [
      'medical_supplies',
      'catering',
      'cleaning',
      'maintenance',
      'equipment',
      'ppe',
      'medication',
      'laundry',
      'training',
      'consultancy',
      'utilities',
      'software',
      'telecare',
      'transport',
      'other',
    ];
  }

  // Get supplier statuses
  List<String> getSupplierStatuses() {
    return ['active', 'inactive', 'suspended', 'pending_approval'];
  }

  // Get risk ratings
  List<String> getRiskRatings() {
    return ['low', 'medium', 'high', 'critical'];
  }

  // Get payment terms
  List<String> getPaymentTerms() {
    return ['7_days', '14_days', '30_days', '60_days', 'prepaid', 'other'];
  }

  // Get compliance statuses
  List<String> getComplianceStatuses() {
    return ['compliant', 'non_compliant', 'pending', 'needs_review'];
  }
}