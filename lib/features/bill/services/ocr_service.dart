import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>> extractBillData(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      
      // Extract bill information
      String title = _extractTitle(fullText);
      double amount = _extractAmount(fullText);
      DateTime? dueDate = _extractDueDate(fullText);

      return {
        'title': title,
        'amount': amount,
        'dueDate': dueDate,
        'rawText': fullText,
      };
    } catch (e) {
      throw Exception('Failed to extract text: $e');
    }
  }

  String _extractTitle(String text) {
    // Look for common bill keywords
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('electricity') ||
          line.toLowerCase().contains('water') ||
          line.toLowerCase().contains('internet') ||
          line.toLowerCase().contains('bill')) {
        return line.trim();
      }
    }
    return lines.isNotEmpty ? lines[0] : 'Unknown Bill';
  }

  double _extractAmount(String text) {
    // Look for RM or $ followed by numbers
    final amountRegex = RegExp(r'(?:RM|MYR|\$)\s*(\d+\.?\d*)');
    final match = amountRegex.firstMatch(text);
    
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    
    // Fallback: look for standalone numbers with decimals
    final numberRegex = RegExp(r'\d+\.\d{2}');
    final numberMatch = numberRegex.firstMatch(text);
    
    return double.tryParse(numberMatch?.group(0) ?? '0') ?? 0.0;
  }

  DateTime? _extractDueDate(String text) {
    // Look for dates in format: DD-MM-YYYY, DD/MM/YYYY, YYYY-MM-DD
    final dateRegex = RegExp(r'(\d{1,2}[-/]\d{1,2}[-/]\d{4})|(\d{4}[-/]\d{1,2}[-/]\d{1,2})');
    final match = dateRegex.firstMatch(text);
    
    if (match != null) {
      try {
        String dateStr = match.group(0)!;
        List<String> parts = dateStr.split(RegExp(r'[-/]'));
        
        if (parts.length == 3) {
          int day, month, year;
          
          // Check if it's YYYY-MM-DD format
          if (parts[0].length == 4) {
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          } else {
            // DD-MM-YYYY format
            day = int.parse(parts[0]);
            month = int.parse(parts[1]);
            year = int.parse(parts[2]);
          }
          
          return DateTime(year, month, day);
        }
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}