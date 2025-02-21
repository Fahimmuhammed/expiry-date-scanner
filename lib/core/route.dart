import 'package:flutter/material.dart';
import '../ui/pages/home_page.dart';
import '../ui/pages/scan_page.dart';
import '../ui/pages/history_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String scan = '/scan';
  static const String history = '/history';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case scan:
        return MaterialPageRoute(builder: (_) => ScanPage());
      case history:
        return MaterialPageRoute(builder: (_) => const ViewHistoryPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
