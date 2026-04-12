import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/business.dart';
import '../../data/knowledge_repository.dart';

class KnowledgeListScreen extends ConsumerStatefulWidget {
  final Business business;

  const KnowledgeListScreen({super.key, required this.business});

  @override
  ConsumerState<KnowledgeListScreen> createState() =>
      _KnowledgeListScreenState();
}

class _KnowledgeListScreenState extends ConsumerState<KnowledgeListScreen> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final botUrl = widget.business.serviceUrl ?? '';
      if (botUrl.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = await ref.read(knowledgeRepositoryProvider).getDocuments(
            botUrl: botUrl,
            businessId: widget.business.userId,
          );

      if (mounted) {
        setState(() {
          _documents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка загрузки: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteDocument(String documentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Удалить документ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
            'Документ "$documentName" и все его фрагменты будут удалены.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ОТМЕНА',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('УДАЛИТЬ',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final botUrl = widget.business.serviceUrl ?? '';
    try {
      final success =
          await ref.read(knowledgeRepositoryProvider).deleteDocument(
                botUrl: botUrl,
                businessId: widget.business.userId,
                documentName: documentName,
              );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Документ удалён'),
              backgroundColor: AppColors.success),
        );
        _loadDocuments();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _showDocumentContent(String documentName) async {
    final botUrl = widget.business.serviceUrl ?? '';
    if (botUrl.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) =>
            FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(knowledgeRepositoryProvider).getChunks(
                botUrl: botUrl,
                businessId: widget.business.userId,
                documentName: documentName,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Ошибка: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error)));
            }
            final chunks = snapshot.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(documentName,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chunks.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.border),
                    itemBuilder: (_, i) {
                      final content = chunks[i]['content'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(content,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 14)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('База знаний',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: _loadDocuments),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _documents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return _buildDocumentCard(doc);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined,
              size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Документов пока нет',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          SizedBox(height: 8),
          Text('Загрузите файлы через "Загрузить базу знаний"',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final name = doc['document_name'] ?? 'Без названия';
    final chunks = doc['chunks_count'] ?? 0;
    final chars = doc['total_chars'] ?? 0;
    final createdAt = doc['created_at'];

    String dateStr = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        dateStr =
            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showDocumentContent(name),
      child: Card(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: AppColors.accent, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                        '$chunks фрагм. • $chars симв.${dateStr.isNotEmpty ? ' • $dateStr' : ''}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                onPressed: () => _deleteDocument(name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
