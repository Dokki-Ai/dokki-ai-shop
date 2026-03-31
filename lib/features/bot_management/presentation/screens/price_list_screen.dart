import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/business.dart';
import '../../providers/bot_management_providers.dart';
import '../../data/price_parser.dart';

class PriceListScreen extends ConsumerStatefulWidget {
  final Business business;

  const PriceListScreen({
    super.key,
    required this.business,
  });

  @override
  ConsumerState<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends ConsumerState<PriceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _parsePrice(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ref.read(priceListRepositoryProvider).getProducts(
            telegramUsername: widget.business.telegramUsername,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickPriceFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final products = await PriceParser.parseFile(result.files.single.path!);
      if (products.isNotEmpty) {
        final success =
            await ref.read(priceListRepositoryProvider).uploadPriceList(
                  telegramUsername: widget.business.telegramUsername,
                  products: products,
                );
        if (success) {
          await _loadProducts();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Поиск товара...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5)),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _loadProducts();
                },
              )
            : const Text(
                'Прайс-лист',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.file_upload_outlined, color: AppColors.accent),
            onPressed: _isLoading ? null : _pickPriceFile,
          ),
          IconButton(
            icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _loadProducts();
                }
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/product-edit', extra: {
            'business': widget.business,
            'product': null,
          });
          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Прайс-лист пуст',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = _products[index];
        return _ProductCard(
          name: product['name'] ?? 'Без названия',
          category: product['category'] ?? 'Общее',
          price: _parsePrice(product['price']),
          onTap: () async {
            final result = await context.push('/product-edit', extra: {
              'business': widget.business,
              'product': product,
            });
            if (result == true) {
              _loadProducts();
            }
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final double price;
  final VoidCallback onTap;

  const _ProductCard({
    required this.name,
    required this.category,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(category,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 8),
                const Text('•',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(
                  '${price.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
