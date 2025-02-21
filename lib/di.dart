import 'package:get_it/get_it.dart';
import 'core/services/ocr_service.dart';
import 'core/services/tts_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton<OCRService>(() => OCRService());
  locator.registerLazySingleton<TTSService>(() => TTSService());
}
