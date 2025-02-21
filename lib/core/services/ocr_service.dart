import 'dart:developer';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;

class OCRService {
  final textRecognizer = GoogleMlKit.vision.textRecognizer();

  // Pre-process Image before OCR
  File _preProcessImage(File imageFile) {
    final image = img.decodeImage(imageFile.readAsBytesSync());

    // Convert to Grayscale
    final grayscaleImage = img.grayscale(image!);

    // Enhance Contrast and Edge Detection
    final contrastEnhancedImage = img.colorOffset(grayscaleImage);

    final edgeEnhancedImage = img.sobel(contrastEnhancedImage, amount: 0);

    // Reduce Noise
    final noiseReducedImage = img.gaussianBlur(edgeEnhancedImage, radius: 2);

    // Save processed image as temporary file
    final processedImageFile = File('${imageFile.path}_processed.jpg');

    processedImageFile.writeAsBytesSync(img.encodeJpg(noiseReducedImage));

    return processedImageFile;
  }

  // Google ML Kit OCR with User-Selected Date Format
  Future<String?> extractExpiryDateWithMLKit(
      File imageFile, String selectedDateFormat) async {
    try {
      final preProcessedImage = _preProcessImage(imageFile);
      final inputImage = InputImage.fromFile(preProcessedImage);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      // Match the Date Pattern according to Selected Format
      String? detectedDate = _extractDate(recognizedText.text);

      log(detectedDate!);
      if (detectedDate != null) {
        String? normalizedDate =
            normalizeDateFormat(detectedDate, selectedDateFormat);
        return normalizedDate;
      }
    } catch (e) {
      print('Error in ML Kit OCR: $e');
    }
    return null;
  }

  // Tesseract OCR with User-Selected Date Format
  Future<String?> extractExpiryDateWithTesseract(
      File imageFile, String selectedDateFormat) async {
    try {
      final preProcessedImage = _preProcessImage(imageFile);

      String text = await FlutterTesseractOcr.extractText(
        preProcessedImage.path,
        language: 'eng+ara',
      );

      String? detectedDate = _extractDate(text);
      log('Tess: ${detectedDate!}');
      if (detectedDate != null) {
        String? normalizedDate =
            normalizeDateFormat(detectedDate, selectedDateFormat);
        return normalizedDate;
      }
    } catch (e) {
      print('Error in Tesseract OCR: $e');
    }
    return null;
  }

  // Extract Date from Text
  String? _extractDate(String text) {
    // Enhanced Date Pattern Matching for Multiple Formats
    RegExp datePattern = RegExp(
      r'\b(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})\b',
      caseSensitive: false,
    );

    if (datePattern.hasMatch(text)) {
      return datePattern.firstMatch(text)?.group(0);
    }
    return null;
  }

  void dispose() {
    textRecognizer.close();
  }
}

String? normalizeDateFormat(String rawDate, String format) {
  try {
    // Split date using common separators
    List<String> parts = rawDate.split(RegExp(r'[\/\-\.]'));

    // Check if the date has exactly 3 parts
    if (parts.length != 3) return null;

    // Zero-pad day and month before processing
    String first = parts[0].padLeft(2, '0');
    String second = parts[1].padLeft(2, '0');
    String third = parts[2];

    // Handle different formats while preserving the user-selected format
    switch (format) {
      case 'DD/MM/YYYY':
        return '$first/$second/$third';
      case 'MM/DD/YYYY':
        return '$second/$first/$third';
      case 'YYYY/MM/DD':
        return '$third/$second/$first';
      default:
        return null;
    }
  } catch (e) {
    print('Date Normalization Error: $e');
  }
  return null;
}

// Helper Function to Pad Single Digits with Zero
String _padZero(int number) => number.toString().padLeft(2, '0');
