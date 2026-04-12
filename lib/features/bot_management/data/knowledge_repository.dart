import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final knowledgeRepositoryProvider = Provider((ref) => KnowledgeRepository());

class KnowledgeRepository {
  /// Получение списка документов (бэкенд возвращает прямой массив [])
  Future<List<Map<String, dynamic>>> getDocuments({
    required String botUrl,
    required String businessId,
  }) async {
    final response = await http.get(
      Uri.parse('$botUrl/api/knowledge/$businessId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Ошибка загрузки базы знаний: ${response.statusCode}');
  }

  /// Получение чанков конкретного документа (бэкенд возвращает { success: true, chunks: [] })
  Future<List<Map<String, dynamic>>> getChunks({
    required String botUrl,
    required String businessId,
    required String documentName,
  }) async {
    final response = await http.get(
      Uri.parse(
          '$botUrl/api/knowledge/$businessId/${Uri.encodeComponent(documentName)}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['chunks'] ?? []);
    }
    throw Exception('Ошибка загрузки содержимого документа');
  }

  /// Удаление документа по названию
  Future<bool> deleteDocument({
    required String botUrl,
    required String businessId,
    required String documentName,
  }) async {
    final response = await http.delete(
      Uri.parse(
          '$botUrl/api/knowledge/$businessId/${Uri.encodeComponent(documentName)}'),
    );
    return response.statusCode == 200;
  }
}
