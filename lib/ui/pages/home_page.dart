import 'package:easy_localization/easy_localization.dart';
import 'package:expiry_date_scanner/core/route.dart';
import 'package:expiry_date_scanner/ui/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('app_title')),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          DropdownButton<Locale>(
            value: context.locale,
            onChanged: (Locale? locale) {
              context.setLocale(locale!);
              (context as Element).markNeedsBuild();
            },
            items: const [
              DropdownMenuItem(
                value: Locale('en', 'US'),
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: Locale('ar', 'SA'),
                child: Text('العربية'),
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.scan);
              },
              child: Text(tr('scan_product')),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.history);
              },
              child: Text(tr('view_history')),
            ),
          ],
        ),
      ),
    );
  }
}
