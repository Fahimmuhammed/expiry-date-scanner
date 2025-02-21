import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expiry_date_scanner/ui/providers/scan_provider.dart';
import 'package:lottie/lottie.dart';

class ScanPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final scanNotifier = ref.read(scanProvider.notifier);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stop Listening FAB
          FloatingActionButton(
            heroTag: 'stopListeningFAB',
            onPressed: () {
              scanNotifier.stopListening();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice Command Stopped')),
              );
            },
            tooltip: 'Stop Listening',
            backgroundColor: Colors.red,
            child: const Icon(Icons.mic_off),
          ),
          const SizedBox(height: 10),
          // Start Listening FAB
          FloatingActionButton(
            heroTag: 'startListeningFAB',
            onPressed: () {
              _showVoiceCommandModal(context, scanNotifier);
            },
            tooltip: 'Voice Command',
            child: const Icon(Icons.mic),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(tr('scan_product')),
        actions: [
          DropdownButton<String>(
            value: scanState.selectedDateFormat,
            items: <String>['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY/MM/DD']
                .map((String format) {
              return DropdownMenuItem<String>(
                value: format,
                child: Text(format),
              );
            }).toList(),
            onChanged: (String? newFormat) {
              if (newFormat != null &&
                  newFormat != scanState.selectedDateFormat) {
                // Update state and rebuild UI
                scanNotifier.setSelectedDateFormat(newFormat);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: Colors.black,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Smart Expiry Status Indicator
              if (scanState.status != null)
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(scanState.status!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _getStatusText(scanState.status!),
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Display the Selected or Captured Image
              if (scanState.imageFile != null)
                Image.file(
                  File(scanState.imageFile!.path),
                  height: 100,
                  width: 200,
                ),

              const SizedBox(height: 10),

              // Loading Indicator - Only when the format is valid and loading is true
              if (scanState.isLoading &&
                  scanState.expiryDate != 'Invalid Format')
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 200,
                    maxHeight: 200,
                  ),
                  child: Lottie.asset(
                    'lib/assets/animations/loader.json',
                    fit: BoxFit.contain,
                  ),
                ),

              // Display Expiry Date or Error Message
              if (scanState.expiryDate != null)
                Column(
                  children: [
                    Text(
                      scanState.expiryDate!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scanState.expiryDate == 'Invalid Format'
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Countdown Timer Display
                    if (scanState.remainingDays != 0)
                      Text(
                        scanState.remainingDays > 0
                            ? '${scanState.remainingDays} days left'
                            : 'Expired ${scanState.remainingDays.abs()} days ago',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scanState.remainingDays > 7
                              ? Colors.green
                              : scanState.remainingDays > 0
                                  ? Colors.yellow.shade800
                                  : Colors.red,
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Button for Picking Image from Gallery
                  ElevatedButton(
                    onPressed: () => scanNotifier.pickImage(),
                    child: Text(tr('select_image')),
                  ),

                  const SizedBox(width: 10),
                  // Button for Scanning Image using Camera
                  ElevatedButton(
                    onPressed: () => scanNotifier.scanImage(),
                    child: const Text('Scan Image'),
                  ),
                ],
              ),

              // Button to Reset Image
              if (scanState.imageFile != null)
                ElevatedButton(
                    onPressed: () => scanNotifier.resetImage(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                    ),
                    child: const Icon(Icons.refresh)),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoiceCommandModal(BuildContext context, ScanNotifier scanNotifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Voice Commands',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.deepOrange),
                title: Text('Scan image from camera'),
                subtitle: Text('Say: scan'),
              ),
              const ListTile(
                leading: Icon(Icons.image, color: Colors.deepOrange),
                title: Text('Scan image from gallery'),
                subtitle: Text('Say: pick'),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    scanNotifier.listenForCommands();
                    Navigator.pop(context); // Close the modal
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Listening for Voice Commands...')),
                    );
                  },
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text('Start Listening'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Get Status Text with Emoji
String _getStatusText(ExpiryStatus status) {
  switch (status) {
    case ExpiryStatus.safe:
      return '🟢 Safe';
    case ExpiryStatus.warning:
      return '🟡 Approaching Expiry';
    case ExpiryStatus.expired:
      return '🔴 Expired';
    default:
      return '';
  }
}

// Get Status Color for Container Background
Color _getStatusColor(ExpiryStatus status) {
  switch (status) {
    case ExpiryStatus.safe:
      return Colors.green.withOpacity(0.4);
    case ExpiryStatus.warning:
      return Colors.yellow.withOpacity(0.5);
    case ExpiryStatus.expired:
      return Colors.redAccent.withOpacity(0.4);
    default:
      return Colors.transparent;
  }
}
