import 'package:hive/hive.dart';

part 'scan_history.g.dart';

@HiveType(typeId: 1)
class ScanHistory {
  @HiveField(0)
  final String imagePath;

  @HiveField(1)
  final String expiryDate;

  @HiveField(2)
  final String status;

  @HiveField(3)
  final DateTime scannedDate;

  ScanHistory({
    required this.imagePath,
    required this.expiryDate,
    required this.status,
    required this.scannedDate,
  });
}
