import 'dart:async';
import 'dart:io';
import 'package:expiry_date_scanner/core/services/tts_service.dart';
import 'package:expiry_date_scanner/data/models/scan_history.dart';
import 'package:expiry_date_scanner/di.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expiry_date_scanner/core/services/ocr_service.dart';

enum ExpiryStatus {
  safe, // 🟢 More than 7 days left
  warning, // 🟡 Less than 7 days left
  expired, // 🔴 Expired
}

class ScanState {
  final XFile? imageFile;
  final String? expiryDate;
  final ExpiryStatus? status;
  final bool isLoading;
  final String selectedDateFormat;
  final int remainingDays;

  ScanState({
    this.imageFile,
    this.expiryDate,
    this.status,
    this.isLoading = false,
    required this.selectedDateFormat,
    this.remainingDays = 0,
  });

  ScanState copyWith({
    XFile? imageFile,
    String? expiryDate,
    ExpiryStatus? status,
    bool? isLoading,
    String? selectedDateFormat,
    int? remainingDays,
  }) {
    return ScanState(
      imageFile: imageFile ?? this.imageFile,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      selectedDateFormat: selectedDateFormat ?? this.selectedDateFormat,
      remainingDays: remainingDays ?? this.remainingDays,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final OCRService _ocrService = locator<OCRService>();
  final TTSService _ttsService = locator<TTSService>();
  Timer? _countdownTimer;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Box<ScanHistory> _scanBox = Hive.box<ScanHistory>('scanHistoryBox');
  List<ScanHistory> _cachedHistory = [];
  DateTime? _lastNotificationDate;

  ScanNotifier() : super(ScanState(selectedDateFormat: 'DD/MM/YYYY'));

  TTSService get ttsService => _ttsService;

  // Store Scan History Locally
  Future<void> _storeScanHistory() async {
    final history = ScanHistory(
      imagePath: state.imageFile?.path ?? '',
      expiryDate: state.expiryDate ?? '',
      status: state.status.toString(),
      scannedDate: DateTime.now(),
    );
    await _scanBox.add(history);
  }

  List<ScanHistory> fetchScanHistory() {
    _cachedHistory = _scanBox.values.toList().cast<ScanHistory>();
    return _cachedHistory;
  }

  // Delete a Scan Record
  Future<void> deleteScan(int index) async {
    await _scanBox.deleteAt(index);
    state = state.copyWith(); // Refresh state
  }

  // Clear All Scan History
  Future<void> clearAllScans() async {
    await _scanBox.clear();
    state = state.copyWith(); // Refresh state
  }

  List<ScanHistory> searchScans(String query) {
    return _cachedHistory.where((scan) {
      return scan.expiryDate.contains(query) || scan.status.contains(query);
    }).toList();
  }

  List<ScanHistory> filterByStatus(String status) {
    return fetchScanHistory().where((scan) {
      return scan.status.toLowerCase().contains(status.toLowerCase());
    }).toList();
  }

  // Pick Image from Gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      state = state.copyWith(imageFile: pickedFile, isLoading: true);
      await _processImage(File(pickedFile.path));
      _speakExpiryStatus();
    }
  }

  // Scan Image using Camera
  Future<void> scanImage() async {
    final picker = ImagePicker();
    final capturedFile = await picker.pickImage(source: ImageSource.camera);
    if (capturedFile != null) {
      state = state.copyWith(imageFile: capturedFile, isLoading: true);
      await _processImage(File(capturedFile.path));
      _speakExpiryStatus();
    }
  }

  // Reset the image and state
  void resetImage() {
    _countdownTimer?.cancel(); // Cancel Timer on Reset
    state = ScanState(
      imageFile: null,
      expiryDate: null,
      status: null,
      isLoading: false,
      selectedDateFormat: state.selectedDateFormat,
      remainingDays: 0,
    );
  }

  // Set Selected Date Format
  void setSelectedDateFormat(String format) {
    state = state.copyWith(selectedDateFormat: format);
  }

  // Process Image using OCR and Calculate Expiry Status
  Future<void> _processImage(File imageFile) async {
    String selectedFormat = state.selectedDateFormat;

    // Extract date using OCR
    final extractedDate = await _ocrService.extractExpiryDateWithMLKit(
            imageFile, selectedFormat) ??
        await _ocrService.extractExpiryDateWithTesseract(
            imageFile, selectedFormat);

    if (extractedDate == null ||
        !isValidDateFormat(extractedDate, selectedFormat)) {
      state = state.copyWith(
        expiryDate: 'Invalid Format',
        status: null,
        isLoading: false,
        remainingDays: 0, // Reset countdown
      );
      return;
    }

    // Normalize and parse the date
    String normalizedDate = normalizeDate(extractedDate, selectedFormat);
    DateTime expiry = parseDate(normalizedDate, selectedFormat);

    final daysLeft = expiry.difference(DateTime.now()).inDays;
    ExpiryStatus status = _calculateExpiryStatus(daysLeft);

    // Update state with expiry date, status, and countdown
    state = state.copyWith(
      expiryDate: normalizedDate,
      status: status,
      isLoading: false,
      remainingDays: daysLeft,
    );

    // Manage Timer Lifecycle
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(days: 1), (timer) {
      final updatedDaysLeft = state.remainingDays - 1;
      state = state.copyWith(remainingDays: updatedDaysLeft);

      ExpiryStatus updatedStatus = _calculateExpiryStatus(updatedDaysLeft);
      if (updatedStatus == ExpiryStatus.warning) {
        _triggerExpiryNotification(updatedDaysLeft);
      }
      state = state.copyWith(status: updatedStatus);
    });

    await _storeScanHistory();
  }

  String normalizeDate(String date, String format) {
    List<String> parts = date.split(RegExp(r'[\/\-\.]'));
    String day, month, year;

    switch (format) {
      case 'DD/MM/YYYY':
        day = parts[0].padLeft(2, '0');
        month = parts[1].padLeft(2, '0');
        year = parts[2];
        return '$day/$month/$year';
      case 'MM/DD/YYYY':
        month = parts[0].padLeft(2, '0');
        day = parts[1].padLeft(2, '0');
        year = parts[2];
        return '$month/$day/$year';
      case 'YYYY/MM/DD':
        year = parts[0];
        month = parts[1].padLeft(2, '0');
        day = parts[2].padLeft(2, '0');
        return '$year/$month/$day';
      default:
        return date;
    }
  }

  DateTime parseDate(String date, String format) {
    List<String> parts = date.split(RegExp(r'[\/\-\.]'));

    switch (format) {
      case 'DD/MM/YYYY':
        return DateTime(
          int.parse(parts[2]), // Year
          int.parse(parts[1]), // Month
          int.parse(parts[0]), // Day
        );
      case 'MM/DD/YYYY':
        return DateTime(
          int.parse(parts[2]), // Year
          int.parse(parts[0]), // Month
          int.parse(parts[1]), // Day
        );
      case 'YYYY/MM/DD':
        return DateTime(
          int.parse(parts[0]), // Year
          int.parse(parts[1]), // Month
          int.parse(parts[2]), // Day
        );
      default:
        throw FormatException("Unsupported date format: $format");
    }
  }

  ExpiryStatus _calculateExpiryStatus(int daysLeft) {
    if (daysLeft < 0) {
      return ExpiryStatus.expired;
    } else if (daysLeft <= 7) {
      return ExpiryStatus.warning;
    } else {
      return ExpiryStatus.safe;
    }
  }

  bool isValidDateFormat(String date, String format) {
    List<String> parts = date.split(RegExp(r'[\/\-\.]'));
    if (parts.length != 3) return false;

    int first = int.parse(parts[0]);
    int second = int.parse(parts[1]);
    int third = int.parse(parts[2]);

    switch (format) {
      case 'DD/MM/YYYY':
        return (first > 0 && first <= 31) && (second > 0 && second <= 12);
      case 'MM/DD/YYYY':
        return (first > 0 && first <= 12) && (second > 0 && second <= 31);
      case 'YYYY/MM/DD':
        return (second > 0 && second <= 12) && (third > 0 && third <= 31);
      default:
        return false;
    }
  }

  void _triggerExpiryNotification(int daysLeft) {
    if (_lastNotificationDate != null &&
        _lastNotificationDate!.isAtSameMomentAs(DateTime.now())) {
      return; // Prevent duplicate notifications
    }
    _lastNotificationDate = DateTime.now();

    const androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Expiry Notifications',
      channelDescription: 'Notifications for approaching expiry dates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    _notificationsPlugin.show(
      0,
      'Product Approaching Expiry',
      'Only $daysLeft days left until expiry!',
      notificationDetails,
      payload: 'approaching_expiry',
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

//speech to text
  void _speakExpiryStatus() {
    if (state.status != null) {
      String statusMessage;
      switch (state.status) {
        case ExpiryStatus.safe:
          statusMessage = "Safe to use";
          break;
        case ExpiryStatus.warning:
          statusMessage = "Approaching expiry";
          break;
        case ExpiryStatus.expired:
          statusMessage = "Expired";
          break;
        default:
          statusMessage = "Expiry status unknown.";
      }
      _ttsService.speak(statusMessage);
    }
  }

//works on real device
  void listenForCommands() async {
    await _ttsService.startListening((command) async {
      command = command.toLowerCase();
      if (command.contains('scan')) {
        await scanImage();
      } else if (command.contains('pick')) {
        await pickImage();
      }
    });
  }

  Future<void> stopListening() async {
    await _ttsService.stopListening();
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(),
);
