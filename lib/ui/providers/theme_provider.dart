import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Hive Box Name for Persisting Theme
const String themeBoxName = 'themeBox';
const String themeModeKey = 'themeModeKey';

// Define the Theme State Notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  // Load the saved theme mode from Hive
  Future<void> _loadTheme() async {
    final box = await Hive.openBox(themeBoxName);
    final savedTheme =
        box.get(themeModeKey, defaultValue: ThemeMode.light.index);
    state = ThemeMode.values[savedTheme];
  }

  // Toggle Theme Mode and Save to Hive
  Future<void> toggleTheme() async {
    state = (state == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    final box = await Hive.openBox(themeBoxName);
    await box.put(themeModeKey, state.index);
  }
}

// Riverpod Provider for Theme
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
