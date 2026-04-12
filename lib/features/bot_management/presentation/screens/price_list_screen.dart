import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/business.dart';
import '../../data/price_list_repository.dart';

class PriceListScreen extends ConsumerStatefulWidget {
  final Business business;

  const PriceListScreen({super.key, required this.business});

  @override
  ConsumerState<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends ConsumerState<PriceListScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Загрузка списка товаров из прайс-листа
  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final botUrl = widget.business.serviceUrl ?? '';
      if (botUrl.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = await ref.read(priceListRepositoryProvider).getProducts(
            botUrl: botUrl,
            businessId: widget.business.userId,
          );

      if (!mounted) return;
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Проверка непосредственно перед использованием context
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _parsePrice(dynamic price) {
    if (price == null) return '0';
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('Прайс-лист',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            color: AppColors.card,
            onSelected: (value) async {
              if (value == 'delete_all') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('Очистка',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content:
                        const Text('Удалить весь прайс-лист безвозвратно?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('ОТМЕНА',
                              style:
                                  TextStyle(color: AppColors.textSecondary))),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('УДАЛИТЬ ВСЁ',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // Проверка после закрытия диалога
                  if (!mounted) return;

                  final botUrl = widget.business.serviceUrl ?? '';
                  try {
                    await ref
                        .read(priceListRepositoryProvider)
                        .deleteAllProducts(
                          botUrl: botUrl,
                          businessId: widget.business.userId,
                        );

                    if (!mounted) return;
                    _loadProducts();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Прайс-лист очищен'),
                          backgroundColor: AppColors.success),
                    );
                  } catch (e) {
                    if (!mounted || !context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Ошибка: $e'),
                          backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'delete_all',
                  child: Text('Удалить весь прайс',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _products.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: AppColors.accent,
                  child: isDesktop ? _buildDesktopTable() : _buildMobileList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Прайс-лист пуст',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          color: AppColors.card,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () async {
              final result = await context.push('/product-edit', extra: {
                'business': widget.business,
                'product': product,
              });
              if (!mounted) return;
              if (result == true) _loadProducts();
            },
            title: Text(product['name'] ?? 'Без названия',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            subtitle: Text(
                'SKU: ${product['sku'] ?? 'N/A'} • ${product['category'] ?? ''}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_parsePrice(product['price'])} AED',
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text('Удаление',
                            style: TextStyle(color: AppColors.textPrimary)),
                        content: const Text('Удалить этот товар?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Отмена',
                                  style: TextStyle(
                                      color: AppColors.textSecondary))),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Удалить',
                                style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      if (!mounted) return;
                      final botUrl = widget.business.serviceUrl ?? '';
                      final sku = (product['sku'] ?? '').toString();
                      try {
                        await ref
                            .read(priceListRepositoryProvider)
                            .deleteProduct(
                              botUrl: botUrl,
                              businessId: widget.business.userId,
                              sku: sku,
                            );

                        if (!mounted) return;
                        _loadProducts();
                      } catch (e) {
                        if (!mounted || !context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Ошибка удаления: $e'),
                              backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: DataTable(
          columns: const [
            DataColumn(
                label: Text('SKU',
                    style: TextStyle(color: AppColors.textSecondary))),
            DataColumn(
                label: Text('Название',
                    style: TextStyle(color: AppColors.textSecondary))),
            DataColumn(
                label: Text('Категория',
                    style: TextStyle(color: AppColors.textSecondary))),
            DataColumn(
                label: Text('Цена',
                    style: TextStyle(color: AppColors.textSecondary))),
            DataColumn(
                label: Text('Действия',
                    style: TextStyle(color: AppColors.textSecondary))),
          ],
          rows: _products.map((product) {
            return DataRow(cells: [
              DataCell(Text(product['sku']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text(product['name']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text(product['category']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.textPrimary))),
              DataCell(Text('${_parsePrice(product['price'])} AED',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold))),
              DataCell(IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: const Text('Удаление',
                          style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text('Удалить товар?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Отмена',
                                style:
                                    TextStyle(color: AppColors.textSecondary))),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Удалить',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    if (!mounted) return;
                    try {
                      await ref.read(priceListRepositoryProvider).deleteProduct(
                            botUrl: widget.business.serviceUrl ?? '',
                            businessId: widget.business.userId,
                            sku: (product['sku'] ?? '').toString(),
                          );

                      if (!mounted) return;
                      _loadProducts();
                    } catch (e) {
                      if (!mounted || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Ошибка удаления: $e'),
                            backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
