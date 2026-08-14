import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/organisation_profile.dart';
import '../../services/invoice_service.dart';

class OrganisationProfileScreen extends StatefulWidget {
  const OrganisationProfileScreen({super.key});

  @override
  State<OrganisationProfileScreen> createState() => _OrganisationProfileScreenState();
}

class _OrganisationProfileScreenState extends State<OrganisationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InvoiceService(Supabase.instance.client);
  bool _loading = true;
  bool _saving = false;

  // Controllers
  final _legalNameController = TextEditingController();
  final _tradingNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _cqcNumberController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _invoicePrefixController = TextEditingController();
  final _invoiceTermsController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _sortCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _taxRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.getOrganisationProfile();
      if (profile != null) {
        _legalNameController.text = profile.legalName;
        _tradingNameController.text = profile.tradingName ?? '';
        _registrationNumberController.text = profile.registrationNumber ?? '';
        _vatNumberController.text = profile.vatNumber ?? '';
        _cqcNumberController.text = profile.cqcRegistrationNumber ?? '';
        _address1Controller.text = profile.addressLine1 ?? '';
        _address2Controller.text = profile.addressLine2 ?? '';
        _cityController.text = profile.city ?? '';
        _countyController.text = profile.county ?? '';
        _postcodeController.text = profile.postcode ?? '';
        _phoneController.text = profile.phone ?? '';
        _emailController.text = profile.email ?? '';
        _websiteController.text = profile.website ?? '';
        _invoicePrefixController.text = profile.invoicePrefix;
        _invoiceTermsController.text = profile.invoiceTerms;
        _bankNameController.text = profile.bankName ?? '';
        _bankAccountNameController.text = profile.bankAccountName ?? '';
        _sortCodeController.text = profile.bankSortCode ?? '';
        _accountNumberController.text = profile.bankAccountNumber ?? '';
        _taxRateController.text = profile.taxRate.toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final profile = OrganisationProfile(
        organisationId: '', // Will be set by service
        legalName: _legalNameController.text,
        tradingName: _tradingNameController.text.isEmpty ? null : _tradingNameController.text,
        registrationNumber: _registrationNumberController.text.isEmpty ? null : _registrationNumberController.text,
        vatNumber: _vatNumberController.text.isEmpty ? null : _vatNumberController.text,
        cqcRegistrationNumber: _cqcNumberController.text.isEmpty ? null : _cqcNumberController.text,
        addressLine1: _address1Controller.text.isEmpty ? null : _address1Controller.text,
        addressLine2: _address2Controller.text.isEmpty ? null : _address2Controller.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        county: _countyController.text.isEmpty ? null : _countyController.text,
        postcode: _postcodeController.text.isEmpty ? null : _postcodeController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        website: _websiteController.text.isEmpty ? null : _websiteController.text,
        invoicePrefix: _invoicePrefixController.text.isEmpty ? 'INV-' : _invoicePrefixController.text,
        invoiceTerms: _invoiceTermsController.text.isEmpty ? '30 days' : _invoiceTermsController.text,
        bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
        bankAccountName: _bankAccountNameController.text.isEmpty ? null : _bankAccountNameController.text,
        bankSortCode: _sortCodeController.text.isEmpty ? null : _sortCodeController.text,
        bankAccountNumber: _accountNumberController.text.isEmpty ? null : _accountNumberController.text,
        taxRate: double.tryParse(_taxRateController.text) ?? 20.0,
      );

      await _service.updateOrganisationProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organisation Profile'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('Business Details', [
                    _buildTextField(_legalNameController, 'Legal Name *', required: true),
                    _buildTextField(_tradingNameController, 'Trading Name'),
                    _buildTextField(_registrationNumberController, 'Company Registration Number'),
                    _buildTextField(_vatNumberController, 'VAT Number'),
                    _buildTextField(_cqcNumberController, 'CQC Registration Number'),
                  ]),
                  _buildSection('Contact Details', [
                    _buildTextField(_address1Controller, 'Address Line 1'),
                    _buildTextField(_address2Controller, 'Address Line 2'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_cityController, 'City')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_countyController, 'County')),
                      ],
                    ),
                    _buildTextField(_postcodeController, 'Postcode'),
                    _buildTextField(_phoneController, 'Phone', keyboardType: TextInputType.phone),
                    _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
                    _buildTextField(_websiteController, 'Website', keyboardType: TextInputType.url),
                  ]),
                  _buildSection('Invoice Settings', [
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_invoicePrefixController, 'Invoice Prefix')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_invoiceTermsController, 'Payment Terms')),
                      ],
                    ),
                    _buildTextField(_taxRateController, 'Tax Rate (%)', keyboardType: TextInputType.number),
                  ]),
                  _buildSection('Bank Details', [
                    _buildTextField(_bankNameController, 'Bank Name'),
                    _buildTextField(_bankAccountNameController, 'Account Name'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_sortCodeController, 'Sort Code', keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_accountNumberController, 'Account Number', keyboardType: TextInputType.number)),
                      ],
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: (v) {
          if (required && (v?.isEmpty ?? true)) return 'Required';
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _tradingNameController.dispose();
    _registrationNumberController.dispose();
    _vatNumberController.dispose();
    _cqcNumberController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _invoicePrefixController.dispose();
    _invoiceTermsController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _sortCodeController.dispose();
    _accountNumberController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }
}