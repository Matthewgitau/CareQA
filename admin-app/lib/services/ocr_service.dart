import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _imagePicker = ImagePicker();

  // Pick image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Scan receipt using Google ML Kit Text Recognition
  Future<Map<String, dynamic>> scanReceipt(File imageFile) async {
    try {
      // Process image with ML Kit
      final inputImage = InputImage.fromFile(imageFile);
      final recognisedText = await _textRecognizer.processImage(inputImage);

      // Extract raw text
      final rawText = recognisedText.text;

      // Parse structured data from OCR text
      final parsedData = _parseReceiptText(rawText);

      return {
        'merchant': parsedData['merchant'] ?? '',
        'date': parsedData['date'] ?? '',
        'total': parsedData['total'] ?? 0.0,
        'subtotal': parsedData['subtotal'] ?? 0.0,
        'tax': parsedData['tax'] ?? 0.0,
        'items': parsedData['items'] ?? [],
        'raw_text': rawText,
        'ocr_confidence': 1.0,
        'ocr_provider': 'google_ml_kit',
      };
    } catch (e) {
      print('OCR Error: $e');
      return _getManualFallback();
    }
  }

  Map<String, dynamic> _parseReceiptText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final result = {
      'merchant': '',
      'date': '',
      'total': 0.0,
      'subtotal': 0.0,
      'tax': 0.0,
      'items': <Map<String, dynamic>>[],
    };

    if (lines.isEmpty) return result;

    // Merchant is usually first line
    result['merchant'] = lines.first;

    // Look for total (variations)
    final totalPatterns = [
      RegExp(r'[Tt]otal\s*[£$€]?\s*([\d,]+\.\d{2})'),
      RegExp(r'[Aa]mount\s*[£$€]?\s*([\d,]+\.\d{2})'),
      RegExp(r'[Tt]otal\s+[£$€]?\s*([\d,]+\.\d{2})'),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        result['total'] = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
        break;
      }
    }

    // Look for subtotal
    final subtotalPattern = RegExp(r'[Ss]ubtotal\s*[£$€]?\s*([\d,]+\.\d{2})');
    final subtotalMatch = subtotalPattern.firstMatch(text);
    if (subtotalMatch != null) {
      result['subtotal'] = double.tryParse(subtotalMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
    }

    // Look for tax
    final taxPattern = RegExp(r'[Tt]ax\s*[£$€]?\s*([\d,]+\.\d{2})');
    final taxMatch = taxPattern.firstMatch(text);
    if (taxMatch != null) {
      result['tax'] = double.tryParse(taxMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
    }

    // Look for date
    final datePatterns = [
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'),
      RegExp(r'(\d{1,2}\s+[A-Za-z]+\s+\d{2,4})'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        result['date'] = match.group(1)!;
        break;
      }
    }

    // Try to extract items (lines with prices)
    final itemPattern = RegExp(r'([A-Za-z].+?)\s+([\d,]+\.\d{2})');
    final itemMatches = itemPattern.allMatches(text);
    final itemsList = result['items'] as List<Map<String, dynamic>>;
    for (final match in itemMatches) {
      if (match.group(1) != null && match.group(2) != null) {
        final description = match.group(1)!.trim();
        final price = double.tryParse(match.group(2)!.replaceAll(',', '')) ?? 0.0;
        if (description.isNotEmpty && price > 0) {
          itemsList.add({
            'description': description,
            'quantity': 1,
            'unit_price': price,
            'total': price,
          });
        }
      }
    }

    // Extract payment method
    if (text.toLowerCase().contains('cash')) {
      result['payment_method'] = 'cash';
    } else if (text.toLowerCase().contains('card') || text.toLowerCase().contains('visa') || text.toLowerCase().contains('mastercard')) {
      result['payment_method'] = 'card';
    } else if (text.toLowerCase().contains('transfer')) {
      result['payment_method'] = 'bank_transfer';
    }

    return result;
  }

  Map<String, dynamic> _getManualFallback() {
    return {
      'merchant': '',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'items': [],
      'subtotal': 0.0,
      'tax': 0.0,
      'total': 0.0,
      'payment_method': 'other',
      'raw_text': '',
      'ocr_confidence': 0.0,
      'ocr_provider': 'manual',
    };
  }

  // Validate extracted data
  bool validateExtractedData(Map<String, dynamic> data) {
    return (data['merchant'] as String?)?.isNotEmpty ?? false &&
           (data['total'] as double?) != null &&
           (data['total'] as double) > 0;
  }

  // Calculate confidence score
  int calculateConfidence(Map<String, dynamic> data) {
    int score = 0;

    if ((data['merchant'] as String?)?.isNotEmpty ?? false) score += 20;
    if ((data['date'] as String?)?.isNotEmpty ?? false) score += 15;
    if ((data['total'] as double?) != null && (data['total'] as double) > 0) score += 25;
    if ((data['subtotal'] as double?) != null) score += 15;
    if ((data['tax'] as double?) != null) score += 10;
    if ((data['items'] as List?)?.isNotEmpty ?? false) score += 15;

    return score;
  }

  void dispose() {
    _textRecognizer.close();
  }
}