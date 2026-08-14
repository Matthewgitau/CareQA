import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt_entry.dart';

class ReceiptService {
  final SupabaseClient _client;

  ReceiptService(this._client);

  // Create new receipt
  Future<ReceiptEntry> createReceipt(Map<String, dynamic> receiptData) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = Map<String, dynamic>.from(receiptData);
      data['created_by'] = user.id;
      data['updated_by'] = user.id;

      final response = await _client
          .from('receipt_entries')
          .insert(data)
          .select()
          .single();

      return ReceiptEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create receipt: $e');
    }
  }

  // Update receipt
  Future<ReceiptEntry> updateReceipt(String id, Map<String, dynamic> updates) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = Map<String, dynamic>.from(updates);
      data['updated_by'] = user.id;

      final response = await _client
          .from('receipt_entries')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return ReceiptEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update receipt: $e');
    }
  }

  // Get all receipts
  Future<List<ReceiptEntry>> getReceipts() async {
    try {
      final response = await _client
          .from('receipt_entries')
          .select()
          .order('receipt_date', ascending: false);

      return (response as List)
          .map((json) => ReceiptEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load receipts: $e');
    }
  }

  // Get single receipt
  Future<ReceiptEntry> getReceipt(String id) async {
    try {
      final response = await _client
          .from('receipt_entries')
          .select()
          .eq('id', id)
          .single();

      return ReceiptEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load receipt: $e');
    }
  }

  // Delete receipt
  Future<void> deleteReceipt(String id) async {
    try {
      await _client
          .from('receipt_entries')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  // Approve receipt
  Future<ReceiptEntry> approveReceipt(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('receipt_entries')
          .update({
            'status': 'approved',
            'approved_by': user.id,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_by': user.id,
          })
          .eq('id', id)
          .select()
          .single();

      return ReceiptEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to approve receipt: $e');
    }
  }

  // Reject receipt
  Future<ReceiptEntry> rejectReceipt(String id, String reason) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('receipt_entries')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'updated_by': user.id,
          })
          .eq('id', id)
          .select()
          .single();

      return ReceiptEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to reject receipt: $e');
    }
  }

  // Get receipt totals by category
  Future<Map<String, double>> getReceiptTotalsByCategory() async {
    try {
      final response = await _client
          .from('receipt_entries')
          .select('category, total_amount');

      final receipts = response as List;
      final totals = <String, double>{};

      for (final receipt in receipts) {
        final category = receipt['category'] as String? ?? 'other';
        final amount = (receipt['total_amount'] as num).toDouble();
        totals[category] = (totals[category] ?? 0) + amount;
      }

      return totals;
    } catch (e) {
      throw Exception('Failed to get category totals: $e');
    }
  }

  // Get receipts by date range
  Future<List<ReceiptEntry>> getReceiptsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('receipt_entries')
          .select()
          .gte('receipt_date', startDate.toIso8601String().split('T')[0])
          .lte('receipt_date', endDate.toIso8601String().split('T')[0])
          .order('receipt_date', ascending: false);

      return (response as List)
          .map((json) => ReceiptEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load receipts by date range: $e');
    }
  }

  // Get receipts by category
  Future<List<ReceiptEntry>> getReceiptsByCategory(String category) async {
    try {
      final response = await _client
          .from('receipt_entries')
          .select()
          .eq('category', category)
          .order('receipt_date', ascending: false);

      return (response as List)
          .map((json) => ReceiptEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load receipts by category: $e');
    }
  }

  // Get receipts by status
  Future<List<ReceiptEntry>> getReceiptsByStatus(String status) async {
    try {
      final response = await _client
          .from('receipt_entries')
          .select()
          .eq('status', status)
          .order('receipt_date', ascending: false);

      return (response as List)
          .map((json) => ReceiptEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load receipts by status: $e');
    }
  }

  // Search receipts
  Future<List<ReceiptEntry>> searchReceipts(String query) async {
    try {
      final response = await _client
          .from('receipt_entries')
          .select()
          .or('merchant_name.ilike.%$query%,expense_notes.ilike.%$query%')
          .order('receipt_date', ascending: false);

      return (response as List)
          .map((json) => ReceiptEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search receipts: $e');
    }
  }

  // Upload receipt image to Supabase Storage
  Future<String> uploadReceiptImage(String filePath) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = 'receipts/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      
      await _client.storage
          .from('receipts')
          .upload(fileName, file);

      return _client.storage
          .from('receipts')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload receipt image: $e');
    }
  }

  // Get receipt categories
  List<String> getReceiptCategories() {
    return [
      'fuel',
      'ppe',
      'uniforms',
      'training',
      'vehicle',
      'insurance',
      'rent',
      'utilities',
      'marketing',
      'office_supplies',
      'food',
      'equipment',
      'maintenance',
      'cleaning',
      'staff',
      'other',
    ];
  }

  // Get payment methods
  List<String> getPaymentMethods() {
    return ['cash', 'card', 'bank_transfer', 'cheque', 'other'];
  }

  // Get status options
  List<String> getStatusOptions() {
    return ['pending', 'approved', 'rejected', 'audited'];
  }
}