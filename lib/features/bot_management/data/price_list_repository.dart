import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Добавлено
import 'package:http/http.dart' as http;

// Вот эта строка решает все ошибки "Undefined name" на экране:
final priceListRepositoryProvider = Provider((ref) => PriceListRepository());

class PriceListRepository {
  /// Массовая загрузка/перезапись (PUT)
  /// [botUrl] — это URL конкретного бота (напр. https://dokki-instance.sevalla.app)
  Future<bool> uploadPriceList({
    required String botUrl,
    required String businessId,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$botUrl/api/prices/$businessId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': products,
        }),
      );

      debugPrint(
          'UPLOAD PRICE LIST RESPONSE: ${response.statusCode} ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Upload Error: $e');
      return false;
    }
  }

  /// Получение списка товаров
  Future<List<Map<String, dynamic>>> getProducts({
    required String botUrl,
    required String businessId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$botUrl/api/prices/$businessId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> products =
            List<Map<String, dynamic>>.from(data['products'] ?? []);

        if (searchQuery != null && searchQuery.isNotEmpty) {
          products = products
              .where((p) => p['name']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
              .toList();
        }
        return products.skip(offset).take(limit).toList();
      } else {
        debugPrint(
            'GET PRODUCTS FAILED: ${response.statusCode} ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('Get Products Error: $e');
      return [];
    }
  }

  /// Создание/Обновление одной позиции (UPSERT)
  Future<bool> updateProduct({
    required String botUrl,
    required String businessId,
    required Map<String, dynamic> product,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$botUrl/api/prices/$businessId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': [product],
        }),
      );

      debugPrint('PRICE API RESPONSE: ${response.statusCode} ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Update Product Error: $e');
      return false;
    }
  }

  /// Удаление одной позиции по SKU
  Future<bool> deleteProduct({
    required String botUrl,
    required String businessId,
    required String sku,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$botUrl/api/prices/$businessId/$sku'),
      );

      debugPrint(
          'DELETE PRODUCT RESPONSE: ${response.statusCode} ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete Product Error: $e');
      return false;
    }
  }

  /// Полная очистка прайс-листа бизнеса
  Future<bool> deleteAllProducts({
    required String botUrl,
    required String businessId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$botUrl/api/prices/$businessId'),
      );

      debugPrint(
          'DELETE ALL PRODUCTS RESPONSE: ${response.statusCode} ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete All Products Error: $e');
      return false;
    }
  }
}
