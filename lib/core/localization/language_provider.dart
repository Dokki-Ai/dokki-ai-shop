import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';

// Провайдер текущего языка
final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.ru);

// Провайдер строк — зависит от languageProvider
final stringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(languageProvider);

  // КРИТИЧЕСКИ ВАЖНО: Обновляем статический контекст для моделей (Bot и т.д.)
  AppStrings.currentLanguage = language;

  return AppStrings(language);
});
