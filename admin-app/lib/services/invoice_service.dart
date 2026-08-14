import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';
import '../models/organisation_profile.dart';

class InvoiceService {
  final SupabaseClient _client;

  InvoiceService(this._client);

  // Organisation Profile
  Future<OrganisationProfile?> getOrganisationProfile() async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) return null;

      final response = await _client
          .from('organisation_profiles')
          .select()
          .eq('organisation_id', orgId)
          .maybeSingle();

      if (response == null) return null;
      return OrganisationProfile.fromJson(response);
    } catch (e) {
      print('Error fetching organisation profile: $e');
      return null;
    }
  }

  Future<void> updateOrganisationProfile(OrganisationProfile profile) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final data = profile.toJson();
      data['organisation_id'] = orgId;
      data['updated_at'] = DateTime.now().toIso8601String();

      await _client.from('organisation_profiles').upsert(data);
    } catch (e) {
      throw Exception('Failed to update organisation profile: $e');
    }
  }

  // Invoices
  Future<List<Invoice>> getInvoices({String? status, DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _client.from('invoices').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('period_start', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('period_end', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Invoice.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  Future<Invoice?> getInvoice(String id) async {
    try {
      final response = await _client.from('invoices').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return Invoice.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final data = invoice.toJson();
      data['organisation_id'] = orgId;
      data['created_by'] = _client.auth.currentUser?.id;
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('invoices').insert(data).select().single();
      return Invoice.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  Future<Invoice> updateInvoice(String id, Map<String, dynamic> data) async {
    try {
      data['updated_by'] = _client.auth.currentUser?.id;
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('invoices').update(data).eq('id', id).select().single();
      return Invoice.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _client.from('invoices').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  Future<void> markAsSent(String id) async {
    try {
      await _client.from('invoices').update({
        'status': 'sent',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark invoice as sent: $e');
    }
  }

  Future<void> markAsPaid(String id, {String? paymentMethod, String? paymentReference}) async {
    try {
      await _client.from('invoices').update({
        'status': 'paid',
        'payment_method': paymentMethod,
        'payment_reference': paymentReference,
        'paid_date': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark invoice as paid: $e');
    }
  }

  Future<Map<String, double>> getInvoiceTotals() async {
    try {
      final response = await _client.from('invoices').select('status, total_amount');
      final invoices = response as List;

      double totalDraft = 0, totalSent = 0, totalPaid = 0, totalOverdue = 0;

      for (final invoice in invoices) {
        final amount = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        final status = invoice['status'] as String? ?? 'draft';

        switch (status) {
          case 'draft':
            totalDraft += amount;
            break;
          case 'sent':
            totalSent += amount;
            break;
          case 'paid':
            totalPaid += amount;
            break;
          case 'overdue':
            totalOverdue += amount;
            break;
        }
      }

      return {
        'draft': totalDraft,
        'sent': totalSent,
        'paid': totalPaid,
        'overdue': totalOverdue,
        'total': totalDraft + totalSent + totalPaid + totalOverdue,
      };
    } catch (e) {
      throw Exception('Failed to fetch invoice totals: $e');
    }
  }

  Future<String?> _getOrganisationId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['organisation_id']?.toString();
    } catch (e) {
      return null;
    }
  }
}