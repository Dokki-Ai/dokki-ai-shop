import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class KnowledgeRepository {
  Future<List<Map<String, dynamic>>> getDocuments({
    required String botUrl,
    required String businessId,
  }) async {
    final response = await http.get(
      Uri.parse('$botUrl/api/knowledge/$businessId'),
    );
    debugPrint(
        'KNOWLEDGE API RESPONSE: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['documents'] ?? []);
    }
    throw Exception('Ошибка загрузки документов');
  }

  Future<bool> deleteDocument({
    required String botUrl,
    required String businessId,
    required String documentName,
  }) async {
    final response = await http.delete(
      Uri.parse(
          '$botUrl/api/knowledge/$businessId/${Uri.encodeComponent(documentName)}'),
    );
    debugPrint(
        'KNOWLEDGE DELETE RESPONSE: ${response.statusCode} ${response.body}');
    return response.statusCode == 200;
  }
}

final knowledgeRepositoryProvider = Provider((ref) => KnowledgeRepository());
