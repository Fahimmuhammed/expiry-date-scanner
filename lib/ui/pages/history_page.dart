import 'dart:io';

import 'package:expiry_date_scanner/data/models/scan_history.dart';
import 'package:expiry_date_scanner/ui/providers/scan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViewHistoryPage extends ConsumerStatefulWidget {
  const ViewHistoryPage({super.key});

  @override
  _ViewHistoryPageState createState() => _ViewHistoryPageState();
}

class _ViewHistoryPageState extends ConsumerState<ViewHistoryPage> {
  String searchQuery = '';
  String filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final scanNotifier = ref.read(scanProvider.notifier);
    List<ScanHistory> scanHistory = scanNotifier.fetchScanHistory();

    // Search and Filter Logic
    if (searchQuery.isNotEmpty) {
      scanHistory = scanNotifier.searchScans(searchQuery);
    }
    if (filterStatus != 'All') {
      scanHistory = scanNotifier.filterByStatus(filterStatus);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await scanNotifier.clearAllScans();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Date or Status',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: filterStatus,
              onChanged: (value) {
                setState(() {
                  filterStatus = value!;
                });
              },
              items: <String>['All', 'Safe', 'Warning', 'Expired']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanHistory.length,
              itemBuilder: (context, index) {
                final scan = scanHistory[index];
                return ListTile(
                  leading: scan.imagePath.isNotEmpty
                      ? Image.file(File(scan.imagePath), width: 50, height: 50)
                      : const Icon(Icons.image_not_supported),
                  title: Text(scan.expiryDate),
                  subtitle: Text(scan.status.replaceAll('ExpiryStatus.', '')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await scanNotifier.deleteScan(index);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
