import 'package:expiry_date_scanner/core/route.dart';

import 'package:expiry_date_scanner/data/models/scan_history.dart';
import 'package:expiry_date_scanner/ui/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Register Adapters
  Hive.registerAdapter(ScanHistoryAdapter());

  // Open Boxes
  await Hive.openBox<ScanHistory>('scanHistoryBox');

  await Hive.openBox('themeBox');

  await EasyLocalization.ensureInitialized();
  setupLocator();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'), // English
          Locale('ar', 'SA'), // Arabic
        ],
        path: 'lib/assets/lang',
        fallbackLocale: const Locale('en', 'US'),
        startLocale: const Locale('en', 'US'),
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.blueGrey.shade900, // Darker shade for texts
          onPrimary: Colors.white, // Text on primary
          secondary: Colors.teal.shade600, // Accent color
          onSecondary: Colors.white, // Text on secondary
          background: Colors.grey.shade100, // Light background
          onBackground: Colors.black87, // Dark text on background
          surface: Colors.white, // Cards and dialogs
          onSurface: Colors.black87, // Text on surfaces
          error: Colors.red, // Error state
          onError: Colors.white, // Text on error
          tertiary: Colors.blueGrey.shade700, // Additional UI accents
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          bodyLarge: const TextStyle(color: Colors.black87),
          bodyMedium: const TextStyle(color: Colors.black87),
          bodySmall: const TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.blueGrey.shade900),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.blueGrey.shade900,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.teal.shade300, // Lighter shade for texts
          onPrimary: Colors.black87, // Text on primary
          secondary: Colors.teal.shade700, // Accent color
          onSecondary: Colors.white, // Text on secondary
          background: Colors.grey.shade900, // Dark background
          onBackground: Colors.white, // Light text on background
          surface: Colors.grey.shade800, // Cards and dialogs
          onSurface: Colors.white, // Text on surfaces
          error: Colors.red.shade300, // Error state
          onError: Colors.black, // Text on error
          tertiary: Colors.teal.shade500,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          bodyLarge: const TextStyle(color: Colors.white),
          bodyMedium: const TextStyle(color: Colors.white70),
          bodySmall: const TextStyle(color: Colors.white54),
          titleLarge: TextStyle(color: Colors.teal.shade300),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
      ),
      themeMode: themeMode,
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.home,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }
}
