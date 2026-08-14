import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/receipt_entry.dart';
import '../../services/receipt_service.dart';
import '../../services/ocr_service.dart';

class ReceiptEntryScreen extends StatefulWidget {
  const ReceiptEntryScreen({super.key});

  @override
  State<ReceiptEntryScreen> createState() => _ReceiptEntryScreenState();
}

class _ReceiptEntryScreenState extends State<ReceiptEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ReceiptService(Supabase.instance.client);
  final _ocrService = OCRService();

  // Receipt Data
  File? _receiptImage;
  bool _isProcessing = false;
  Map<String, dynamic> _extractedData = {};

  // Form Controllers
  final _merchantController = TextEditingController();
  final _merchantAddressController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _taxController = TextEditingController();
  final _totalController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  String? _selectedCurrency;
  String? _expenseType; // 'business' or 'non_business'
  bool _showCustomCategory = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toIso8601String().split('T')[0];
    _selectedCurrency = 'GBP';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _ocrService.pickImage(source);
      if (image != null) {
        setState(() {
          _receiptImage = image;
          _isProcessing = true;
        });
        await _processReceiptImage(image);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processReceiptImage(File image) async {
    try {
      final data = await _ocrService.scanReceipt(image);
      setState(() {
        _extractedData = data;
        _merchantController.text = data['merchant'] ?? '';
        if (data['total'] != null) {
          _totalController.text = data['total'].toString();
        }
        if (data['date'] != null) {
          _dateController.text = data['date'];
        }
        if (data['items'] != null) {
          _items = List<Map<String, dynamic>>.from(data['items']);
        }
        if (data['subtotal'] != null) {
          _subtotalController.text = data['subtotal'].toString();
        }
        if (data['tax'] != null) {
          _taxController.text = data['tax'].toString();
        }
        if (data['payment_method'] != null) {
          _selectedPaymentMethod = data['payment_method'];
        }
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt scanned successfully! Please verify the data.')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $e. Please enter manually.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _submitReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Upload image first
      String? imageUrl;
      if (_receiptImage != null) {
        try {
          imageUrl = await _service.uploadReceiptImage(_receiptImage!.path);
        } catch (e) {
          print('Image upload failed: $e');
          // Continue without image
        }
      }

      // Determine final category value
      String? finalCategory = _selectedCategory;
      if (_expenseType == 'non_business' && _customCategoryController.text.isNotEmpty) {
        finalCategory = _customCategoryController.text;
      }

      // Save receipt data
      final receipt = {
        'merchant_name': _merchantController.text,
        'merchant_address': _merchantAddressController.text.isEmpty ? null : _merchantAddressController.text,
        'receipt_date': _dateController.text,
        'receipt_time': _timeController.text.isEmpty ? null : _timeController.text,
        'subtotal': double.tryParse(_subtotalController.text) ?? 0,
        'tax_amount': double.tryParse(_taxController.text) ?? 0,
        'total_amount': double.tryParse(_totalController.text) ?? 0,
        'currency': _selectedCurrency ?? 'GBP',
        'payment_method': _selectedPaymentMethod,
        'category': finalCategory,
        'expense_category': _expenseType == 'business' ? _selectedCategory : 'other',
        'items': _items,
        'original_photo_url': imageUrl,
        'expense_notes': _notesController.text.isEmpty ? null : _notesController.text,
        'receipt_data': _extractedData.isNotEmpty ? _extractedData : null,
        'status': 'pending',
      };

      await _service.createReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved successfully!'), backgroundColor: Colors.green),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_receiptImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _receiptImage = null),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_receiptImage != null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _receiptImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Retake'),
                                onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.photo_library),
                                label: const Text('New Photo'),
                                onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('No receipt image'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_isProcessing)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Processing receipt...'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Merchant Details
            _buildSectionHeader('Merchant Details'),
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _merchantAddressController,
              decoration: const InputDecoration(
                labelText: 'Merchant Address',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Transaction Details
            _buildSectionHeader('Transaction Details'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _dateController.text = date.toIso8601String().split('T')[0];
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_dateController.text.isNotEmpty ? _dateController.text : 'Select date'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
                      );
                      if (time != null) {
                        setState(() {
                          _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_timeController.text.isNotEmpty ? _timeController.text : 'Select time'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Items
            _buildSectionHeader('Items'),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(item['description'] ?? ''),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('£${item['total']?.toStringAsFixed(2) ?? '0.00'}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() => _items.removeAt(index));
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              onPressed: _showAddItemDialog,
            ),

            const SizedBox(height: 12),

            // Currency
            _buildSectionHeader('Currency'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
              value: _selectedCurrency,
              items: const [
                DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedCurrency = v;
                });
              },
            ),

            const SizedBox(height: 12),

            // Amounts
            _buildSectionHeader('Amounts'),
            TextFormField(
              controller: _subtotalController,
              decoration: const InputDecoration(
                labelText: 'Subtotal',
                border: OutlineInputBorder(),
                prefixText: '£ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxController,
              decoration: const InputDecoration(
                labelText: 'Tax',
                border: OutlineInputBorder(),
                prefixText: '£ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalController,
              decoration: const InputDecoration(
                labelText: 'Total *',
                border: OutlineInputBorder(),
                prefixText: '£ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (double.tryParse(v!) == null) return 'Invalid amount';
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Payment Method
            _buildSectionHeader('Payment Method'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              value: _selectedPaymentMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _selectedPaymentMethod = v),
            ),

            const SizedBox(height: 12),

            // Expense Type (Business vs Non-Business)
            _buildSectionHeader('Expense Type'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Expense Type *',
                border: OutlineInputBorder(),
              ),
              value: _expenseType,
              items: const [
                DropdownMenuItem(value: 'business', child: Text('Business Expense')),
                DropdownMenuItem(value: 'non_business', child: Text('Non-Business Expense')),
              ],
              onChanged: (v) {
                setState(() {
                  _expenseType = v;
                  _selectedCategory = null;
                  _customCategoryController.clear();
                  _showCustomCategory = v == 'non_business';
                });
              },
              validator: (v) => v == null ? 'Required' : null,
            ),

            const SizedBox(height: 12),

            // Category (Business sub-categories)
            if (_expenseType == 'business') ...[
              _buildSectionHeader('Business Category'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Business Category *',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'ppe', child: Text('PPE')),
                  DropdownMenuItem(value: 'office_supplies', child: Text('Office Supplies')),
                  DropdownMenuItem(value: 'miscellaneous', child: Text('Miscellaneous')),
                  DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                  DropdownMenuItem(value: 'vehicle', child: Text('Vehicle')),
                  DropdownMenuItem(value: 'uniforms', child: Text('Uniforms')),
                  DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                  DropdownMenuItem(value: 'training', child: Text('Training')),
                  DropdownMenuItem(value: 'insurance', child: Text('Insurance')),
                  DropdownMenuItem(value: 'rent', child: Text('Rent')),
                  DropdownMenuItem(value: 'utilities', child: Text('Utilities')),
                  DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                  DropdownMenuItem(value: 'food', child: Text('Food')),
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],

            // Category (Non-Business - custom text)
            if (_showCustomCategory) ...[
              _buildSectionHeader('Non-Business Category'),
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Enter category name *',
                  hintText: 'e.g. Personal, Medical, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                onChanged: (v) => _selectedCategory = v,
              ),
            ],

            const SizedBox(height: 12),

            // Notes
            _buildSectionHeader('Notes'),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _submitReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (£)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final description = descriptionController.text;
              final quantity = int.tryParse(quantityController.text) ?? 1;
              final price = double.tryParse(priceController.text) ?? 0;
              if (description.isNotEmpty) {
                setState(() {
                  _items.add({
                    'description': description,
                    'quantity': quantity,
                    'unit_price': price,
                    'total': price * quantity,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}