import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';

class PriceListRepository {
  /// Массовая загрузка/перезапись (DELETE + INSERT)
  Future<bool> uploadPriceList({
    required String telegramUsername,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.botBaseUrl}/api/prices/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telegram_username': telegramUsername,
          'products': products,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Upload Error: $e');
      return false;
    }
  }

  /// Добавление товаров без удаления существующих (Задача 34)
  Future<bool> addProducts({
    required String telegramUsername,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      // Временное решение: последовательный UPSERT через update-single
      for (final product in products) {
        await updateProduct(
          telegramUsername: telegramUsername,
          product: product,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Add Products Error: $e');
      return false;
    }
  }

  /// Получение списка товаров
  Future<List<Map<String, dynamic>>> getProducts({
    required String telegramUsername,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.botBaseUrl}/api/prices/by-username/$telegramUsername'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> products =
            List<Map<String, dynamic>>.from(data['products']);

        if (searchQuery != null && searchQuery.isNotEmpty) {
          products = products
              .where((p) => p['name']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
              .toList();
        }
        return products.skip(offset).take(limit).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Создание/Обновление одной позиции
  Future<bool> updateProduct({
    required String telegramUsername,
    required Map<String, dynamic> product,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.botBaseUrl}/api/prices/update-single'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telegram_username': telegramUsername,
          'product': product,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Update Product Error: $e');
      return false;
    }
  }

  /// Удаление одной позиции
  Future<bool> deleteProduct({
    required String telegramUsername,
    required String productId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.botBaseUrl}/api/prices/delete-single'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telegram_username': telegramUsername,
          'product_id': productId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
