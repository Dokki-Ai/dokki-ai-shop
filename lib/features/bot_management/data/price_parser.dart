import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

class PriceParser {
  /// Главная точка входа: маршрутизация по расширению
  static Future<List<Map<String, dynamic>>> parseFile(String filePath) async {
    if (filePath.endsWith('.csv')) {
      return _parseCsv(filePath);
    } else if (filePath.endsWith('.txt')) {
      return _parseTxt(filePath);
    } else {
      // По умолчанию считаем Excel
      return _parseExcel(filePath);
    }
  }

  /// Парсинг текстовых файлов .txt
  static Future<List<Map<String, dynamic>>> _parseTxt(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      return _parseTextContent(content);
    } catch (e) {
      debugPrint('Ошибка чтения TXT: $e');
      return [];
    }
  }

  /// Универсальный парсер текстового контента (Regex)
  static List<Map<String, dynamic>> _parseTextContent(String text) {
    final products = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Паттерны для распознавания:
      // 1. "Название - 1000"
      // 2. "Название 1000 руб/р/₽/aed/$"
      // 3. "Название: 1000"
      final patterns = [
        RegExp(r'(.+?)\s*[-–—]\s*(\d+)', caseSensitive: false),
        RegExp(r'(.+?)\s+(\d+)\s*(?:руб|₽|р|aed|\$)', caseSensitive: false),
        RegExp(r'(.+?):\s*(\d+)', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(trimmedLine);
        if (match != null) {
          products.add({
            'name': match.group(1)!.trim(),
            'price': _parsePrice(match.group(2)),
            'category': 'Общее',
            'description': '',
          });
          break;
        }
      }
    }

    return products;
  }

  /// Парсинг Excel (.xlsx, .xls)
  static Future<List<Map<String, dynamic>>> _parseExcel(String filePath) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;

      if (rows.isEmpty) return [];

      final products = <Map<String, dynamic>>[];

      // Начинаем со второй строки (i=1), пропуская заголовки
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row[0]?.value == null) continue;

        products.add({
          'name': row[0]?.value?.toString() ?? '',
          'price': _parsePrice(row.length > 1 ? row[1]?.value : null),
          'category': row.length > 2 ? row[2]?.value?.toString() : null,
          'description': row.length > 3 ? row[3]?.value?.toString() : null,
        });
      }

      return products;
    } catch (e) {
      debugPrint('Ошибка парсинга Excel: $e');
      return [];
    }
  }

  /// Парсинг CSV
  static Future<List<Map<String, dynamic>>> _parseCsv(String filePath) async {
    try {
      final lines = await File(filePath).readAsLines();
      if (lines.isEmpty) return [];

      final products = <Map<String, dynamic>>[];

      // Пропускаем заголовки
      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.isEmpty || parts[0].trim().isEmpty) continue;

        products.add({
          'name': parts[0].trim(),
          'price': _parsePrice(parts.length > 1 ? parts[1] : null),
          'category': parts.length > 2 ? parts[2].trim() : null,
          'description': parts.length > 3 ? parts[3].trim() : null,
        });
      }

      return products;
    } catch (e) {
      debugPrint('Ошибка парсинга CSV: $e');
      return [];
    }
  }

  /// Утилита очистки цены: оставляет только цифры и точку
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final str = value.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(str) ?? 0.0;
  }
}
