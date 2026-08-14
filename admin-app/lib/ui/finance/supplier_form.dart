import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supplier.dart';
import '../../services/supplier_service.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final SupplierService _supplierService = SupplierService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Section 1: Supplier Details
  final _supplierNameController = TextEditingController();
  final _tradingNameController = TextEditingController();
  String? _selectedType;
  String? _selectedStatus;

  // Section 2: Contact Information
  final _contactNameController = TextEditingController();
  final _contactTitleController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactMobileController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _websiteUrlController = TextEditingController();

  // Section 3: Registration & Compliance
  final _companyRegNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _cqcRegNumberController = TextEditingController();
  final _nhsSupplierCodeController = TextEditingController();
  final List<String> _selectedIsoCertifications = [];

  // Section 4: Insurance
  final _insuranceProviderController = TextEditingController();
  final _insurancePolicyNumberController = TextEditingController();
  DateTime? _publicLiabilityExpiry;
  DateTime? _employersLiabilityExpiry;
  DateTime? _professionalIndemnityExpiry;

  // Section 5: Compliance Documents
  final _contractUrlController = TextEditingController();
  final _dataSharingAgreementUrlController = TextEditingController();
  final _dbsPolicyUrlController = TextEditingController();
  final _healthSafetyPolicyUrlController = TextEditingController();
  final _qualityPolicyUrlController = TextEditingController();
  final _equalOpportunitiesPolicyUrlController = TextEditingController();
  final _environmentalPolicyUrlController = TextEditingController();
  final _safeguardingPolicyUrlController = TextEditingController();
  final _whistleblowingPolicyUrlController = TextEditingController();

  // Section 6: Financial Details
  String? _selectedPaymentTerms;
  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankSortCodeController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _invoicingNotesController = TextEditingController();

  // Section 7: Performance & Risk
  int? _performanceRating;
  String? _riskRating;
  DateTime? _lastPerformanceReviewDate;
  DateTime? _nextPerformanceReviewDate;
  int? _qualityRating;
  int? _valueRating;

  // Section 8: Contract Details
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  final _contractValueController = TextEditingController();
  final _contractRenewalTermsController = TextEditingController();
  int? _noticePeriodWeeks;

  // Section 9: Service Details
  final List<String> _selectedServices = [];
  final _specialRequirementsController = TextEditingController();
  final _hoursOfOperationController = TextEditingController();
  final _emergencyContactProcedureController = TextEditingController();

  // Section 10: Compliance Checks
  DateTime? _lastComplianceCheckDate;
  DateTime? _nextComplianceCheckDate;
  final _complianceNotesController = TextEditingController();

  // Section 11: Notes
  final _notesController = TextEditingController();
  final _internalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _loadSupplierData(widget.supplier!);
    }
  }

  void _loadSupplierData(Supplier supplier) {
    _supplierNameController.text = supplier.supplierName;
    _tradingNameController.text = supplier.tradingName ?? '';
    _selectedType = supplier.supplierType;
    _selectedStatus = supplier.supplierStatus;
    _contactNameController.text = supplier.contactName ?? '';
    _contactTitleController.text = supplier.contactTitle ?? '';
    _contactEmailController.text = supplier.contactEmail ?? '';
    _contactPhoneController.text = supplier.contactPhone ?? '';
    _contactMobileController.text = supplier.contactMobile ?? '';
    _addressLine1Controller.text = supplier.addressLine1 ?? '';
    _addressLine2Controller.text = supplier.addressLine2 ?? '';
    _cityController.text = supplier.city ?? '';
    _countyController.text = supplier.county ?? '';
    _postcodeController.text = supplier.postcode ?? '';
    _websiteUrlController.text = supplier.websiteUrl ?? '';
    _companyRegNumberController.text = supplier.companyRegistrationNumber ?? '';
    _vatNumberController.text = supplier.vatNumber ?? '';
    _cqcRegNumberController.text = supplier.cqcRegistrationNumber ?? '';
    _nhsSupplierCodeController.text = supplier.nhsSupplierCode ?? '';
    _selectedIsoCertifications.addAll(supplier.isoCertifications ?? []);
    _insuranceProviderController.text = supplier.insuranceProvider ?? '';
    _insurancePolicyNumberController.text = supplier.insurancePolicyNumber ?? '';
    _publicLiabilityExpiry = supplier.publicLiabilityExpiry;
    _employersLiabilityExpiry = supplier.employersLiabilityExpiry;
    _professionalIndemnityExpiry = supplier.professionalIndemnityExpiry;
    _contractUrlController.text = supplier.contractUrl ?? '';
    _dataSharingAgreementUrlController.text = supplier.dataSharingAgreementUrl ?? '';
    _dbsPolicyUrlController.text = supplier.dbsPolicyUrl ?? '';
    _healthSafetyPolicyUrlController.text = supplier.healthSafetyPolicyUrl ?? '';
    _qualityPolicyUrlController.text = supplier.qualityPolicyUrl ?? '';
    _equalOpportunitiesPolicyUrlController.text = supplier.equalOpportunitiesPolicyUrl ?? '';
    _environmentalPolicyUrlController.text = supplier.environmentalPolicyUrl ?? '';
    _safeguardingPolicyUrlController.text = supplier.safeguardingPolicyUrl ?? '';
    _whistleblowingPolicyUrlController.text = supplier.whistleblowingPolicyUrl ?? '';
    _selectedPaymentTerms = supplier.paymentTerms;
    _bankNameController.text = supplier.bankName ?? '';
    _bankAccountNameController.text = supplier.bankAccountName ?? '';
    _bankSortCodeController.text = supplier.bankSortCode ?? '';
    _bankAccountNumberController.text = supplier.bankAccountNumber ?? '';
    _invoicingNotesController.text = supplier.invoicingNotes ?? '';
    _performanceRating = supplier.performanceRating;
    _riskRating = supplier.riskRating;
    _lastPerformanceReviewDate = supplier.lastPerformanceReviewDate;
    _nextPerformanceReviewDate = supplier.nextPerformanceReviewDate;
    _qualityRating = supplier.qualityRating;
    _valueRating = supplier.valueRating;
    _contractStartDate = supplier.contractStartDate;
    _contractEndDate = supplier.contractEndDate;
    _contractValueController.text = supplier.contractValue?.toString() ?? '';
    _contractRenewalTermsController.text = supplier.contractRenewalTerms ?? '';
    _noticePeriodWeeks = supplier.noticePeriodWeeks;
    _selectedServices.addAll(supplier.servicesProvided ?? []);
    _specialRequirementsController.text = supplier.specialRequirements ?? '';
    _hoursOfOperationController.text = supplier.hoursOfOperation ?? '';
    _emergencyContactProcedureController.text = supplier.emergencyContactProcedure ?? '';
    _lastComplianceCheckDate = supplier.lastComplianceCheckDate;
    _nextComplianceCheckDate = supplier.nextComplianceCheckDate;
    _complianceNotesController.text = supplier.complianceNotes ?? '';
    _notesController.text = supplier.notes ?? '';
    _internalNotesController.text = supplier.internalNotes ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supplier = Supplier(
        id: widget.supplier?.id ?? '',
        supplierName: _supplierNameController.text,
        tradingName: _tradingNameController.text.isEmpty ? null : _tradingNameController.text,
        supplierType: _selectedType,
        supplierStatus: _selectedStatus ?? 'active',
        contactName: _contactNameController.text.isEmpty ? null : _contactNameController.text,
        contactTitle: _contactTitleController.text.isEmpty ? null : _contactTitleController.text,
        contactEmail: _contactEmailController.text.isEmpty ? null : _contactEmailController.text,
        contactPhone: _contactPhoneController.text.isEmpty ? null : _contactPhoneController.text,
        contactMobile: _contactMobileController.text.isEmpty ? null : _contactMobileController.text,
        addressLine1: _addressLine1Controller.text.isEmpty ? null : _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text.isEmpty ? null : _addressLine2Controller.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        county: _countyController.text.isEmpty ? null : _countyController.text,
        postcode: _postcodeController.text.isEmpty ? null : _postcodeController.text,
        websiteUrl: _websiteUrlController.text.isEmpty ? null : _websiteUrlController.text,
        companyRegistrationNumber: _companyRegNumberController.text.isEmpty ? null : _companyRegNumberController.text,
        vatNumber: _vatNumberController.text.isEmpty ? null : _vatNumberController.text,
        cqcRegistrationNumber: _cqcRegNumberController.text.isEmpty ? null : _cqcRegNumberController.text,
        nhsSupplierCode: _nhsSupplierCodeController.text.isEmpty ? null : _nhsSupplierCodeController.text,
        isoCertifications: _selectedIsoCertifications.isEmpty ? null : _selectedIsoCertifications,
        insuranceProvider: _insuranceProviderController.text.isEmpty ? null : _insuranceProviderController.text,
        insurancePolicyNumber: _insurancePolicyNumberController.text.isEmpty ? null : _insurancePolicyNumberController.text,
        publicLiabilityExpiry: _publicLiabilityExpiry,
        employersLiabilityExpiry: _employersLiabilityExpiry,
        professionalIndemnityExpiry: _professionalIndemnityExpiry,
        contractUrl: _contractUrlController.text.isEmpty ? null : _contractUrlController.text,
        dataSharingAgreementUrl: _dataSharingAgreementUrlController.text.isEmpty ? null : _dataSharingAgreementUrlController.text,
        dbsPolicyUrl: _dbsPolicyUrlController.text.isEmpty ? null : _dbsPolicyUrlController.text,
        healthSafetyPolicyUrl: _healthSafetyPolicyUrlController.text.isEmpty ? null : _healthSafetyPolicyUrlController.text,
        qualityPolicyUrl: _qualityPolicyUrlController.text.isEmpty ? null : _qualityPolicyUrlController.text,
        equalOpportunitiesPolicyUrl: _equalOpportunitiesPolicyUrlController.text.isEmpty ? null : _equalOpportunitiesPolicyUrlController.text,
        environmentalPolicyUrl: _environmentalPolicyUrlController.text.isEmpty ? null : _environmentalPolicyUrlController.text,
        safeguardingPolicyUrl: _safeguardingPolicyUrlController.text.isEmpty ? null : _safeguardingPolicyUrlController.text,
        whistleblowingPolicyUrl: _whistleblowingPolicyUrlController.text.isEmpty ? null : _whistleblowingPolicyUrlController.text,
        paymentTerms: _selectedPaymentTerms ?? '30_days',
        bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
        bankAccountName: _bankAccountNameController.text.isEmpty ? null : _bankAccountNameController.text,
        bankSortCode: _bankSortCodeController.text.isEmpty ? null : _bankSortCodeController.text,
        bankAccountNumber: _bankAccountNumberController.text.isEmpty ? null : _bankAccountNumberController.text,
        invoicingNotes: _invoicingNotesController.text.isEmpty ? null : _invoicingNotesController.text,
        performanceRating: _performanceRating,
        riskRating: _riskRating,
        lastPerformanceReviewDate: _lastPerformanceReviewDate,
        nextPerformanceReviewDate: _nextPerformanceReviewDate,
        qualityRating: _qualityRating,
        valueRating: _valueRating,
        lastComplianceCheckDate: _lastComplianceCheckDate,
        nextComplianceCheckDate: _nextComplianceCheckDate,
        complianceNotes: _complianceNotesController.text.isEmpty ? null : _complianceNotesController.text,
        contractStartDate: _contractStartDate,
        contractEndDate: _contractEndDate,
        contractValue: _contractValueController.text.isEmpty ? null : double.tryParse(_contractValueController.text),
        contractRenewalTerms: _contractRenewalTermsController.text.isEmpty ? null : _contractRenewalTermsController.text,
        noticePeriodWeeks: _noticePeriodWeeks,
        servicesProvided: _selectedServices.isEmpty ? null : _selectedServices,
        specialRequirements: _specialRequirementsController.text.isEmpty ? null : _specialRequirementsController.text,
        hoursOfOperation: _hoursOfOperationController.text.isEmpty ? null : _hoursOfOperationController.text,
        emergencyContactProcedure: _emergencyContactProcedureController.text.isEmpty ? null : _emergencyContactProcedureController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        internalNotes: _internalNotesController.text.isEmpty ? null : _internalNotesController.text,
        createdBy: widget.supplier?.createdBy,
        createdAt: widget.supplier?.createdAt,
        updatedBy: widget.supplier?.updatedBy,
        updatedAt: widget.supplier?.updatedAt,
        organisationId: widget.supplier?.organisationId,
      );

      if (widget.supplier == null) {
        await _supplierService.createSupplier(supplier);
      } else {
        await _supplierService.updateSupplier(supplier.id, supplier.toJson());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.supplier == null ? 'Supplier created successfully' : 'Supplier updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Supplier Details'),
            TextFormField(
              controller: _supplierNameController,
              decoration: const InputDecoration(labelText: 'Supplier Name *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tradingNameController,
              decoration: const InputDecoration(labelText: 'Trading Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Supplier Type *', border: OutlineInputBorder()),
              value: _selectedType,
              items: _supplierService.getSupplierTypes().map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              value: _selectedStatus,
              items: _supplierService.getSupplierStatuses().map((status) => DropdownMenuItem(
                value: status,
                child: Text(status.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Contact Information'),
            TextFormField(
              controller: _contactNameController,
              decoration: const InputDecoration(labelText: 'Contact Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactTitleController,
              decoration: const InputDecoration(labelText: 'Contact Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactEmailController,
              decoration: const InputDecoration(labelText: 'Contact Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactMobileController,
              decoration: const InputDecoration(labelText: 'Contact Mobile', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(labelText: 'Address Line 1', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(labelText: 'Address Line 2', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _countyController,
                    decoration: const InputDecoration(labelText: 'County', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postcodeController,
              decoration: const InputDecoration(labelText: 'Postcode', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteUrlController,
              decoration: const InputDecoration(labelText: 'Website URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Registration & Compliance Numbers'),
            TextFormField(
              controller: _companyRegNumberController,
              decoration: const InputDecoration(labelText: 'Company Registration Number *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vatNumberController,
              decoration: const InputDecoration(labelText: 'VAT Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cqcRegNumberController,
              decoration: const InputDecoration(labelText: 'CQC Registration Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nhsSupplierCodeController,
              decoration: const InputDecoration(labelText: 'NHS Supplier Code', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Insurance Details'),
            TextFormField(
              controller: _insuranceProviderController,
              decoration: const InputDecoration(labelText: 'Insurance Provider', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _insurancePolicyNumberController,
              decoration: const InputDecoration(labelText: 'Insurance Policy Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _publicLiabilityExpiry ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _publicLiabilityExpiry = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Public Liability Expiry', border: OutlineInputBorder()),
                child: Text(_publicLiabilityExpiry != null ? DateFormat('dd/MM/yyyy').format(_publicLiabilityExpiry!) : 'Select date'),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _employersLiabilityExpiry ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _employersLiabilityExpiry = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Employers Liability Expiry', border: OutlineInputBorder()),
                child: Text(_employersLiabilityExpiry != null ? DateFormat('dd/MM/yyyy').format(_employersLiabilityExpiry!) : 'Select date'),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _professionalIndemnityExpiry ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _professionalIndemnityExpiry = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Professional Indemnity Expiry', border: OutlineInputBorder()),
                child: Text(_professionalIndemnityExpiry != null ? DateFormat('dd/MM/yyyy').format(_professionalIndemnityExpiry!) : 'Select date'),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Financial Details'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Payment Terms', border: OutlineInputBorder()),
              value: _selectedPaymentTerms,
              items: _supplierService.getPaymentTerms().map((terms) => DropdownMenuItem(
                value: terms,
                child: Text(terms.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (value) => setState(() => _selectedPaymentTerms = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountNameController,
              decoration: const InputDecoration(labelText: 'Bank Account Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bankSortCodeController,
                    decoration: const InputDecoration(labelText: 'Sort Code', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bankAccountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invoicingNotesController,
              decoration: const InputDecoration(labelText: 'Invoicing Notes', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Performance & Risk'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Performance Rating', border: OutlineInputBorder()),
                    value: _performanceRating,
                    items: List.generate(5, (index) => index + 1).map((rating) => DropdownMenuItem(
                      value: rating,
                      child: Row(
                        children: [
                          ...List.generate(rating, (i) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                          ...List.generate(5 - rating, (i) => const Icon(Icons.star_border, color: Colors.grey, size: 16)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => _performanceRating = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Risk Rating', border: OutlineInputBorder()),
                    value: _riskRating,
                    items: _supplierService.getRiskRatings().map((risk) => DropdownMenuItem(
                      value: risk,
                      child: Text(risk.toUpperCase()),
                    )).toList(),
                    onChanged: (value) => setState(() => _riskRating = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Contract Details'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _contractStartDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _contractStartDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Contract Start Date', border: OutlineInputBorder()),
                child: Text(_contractStartDate != null ? DateFormat('dd/MM/yyyy').format(_contractStartDate!) : 'Select date'),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _contractEndDate ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _contractEndDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Contract End Date', border: OutlineInputBorder()),
                child: Text(_contractEndDate != null ? DateFormat('dd/MM/yyyy').format(_contractEndDate!) : 'Select date'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contractValueController,
              decoration: const InputDecoration(labelText: 'Contract Value (£)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Notes'),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _internalNotesController,
              decoration: const InputDecoration(labelText: 'Internal Notes (Confidential)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.supplier == null ? 'Create Supplier' : 'Update Supplier', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }
}