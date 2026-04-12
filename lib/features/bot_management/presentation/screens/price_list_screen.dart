import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/bot_management_providers.dart';
import '../../domain/business.dart';

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
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Загрузка списка товаров
  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final botUrl = widget.business.serviceUrl ?? '';

      if (botUrl.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // ИСПРАВЛЕНО: Используем UUID бизнеса (id) вместо botId для корректного поиска в БД
      final data = await ref.read(priceListRepositoryProvider).getProducts(
            botUrl: botUrl,
            businessId: widget.business.id,
          );

      if (mounted) {
        setState(() {
          _products = data;
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

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      if (columnIndex == 0) {
        _products.sort((a, b) => ascending
            ? (a['name'] ?? '').compareTo(b['name'] ?? '')
            : (b['name'] ?? '').compareTo(a['name'] ?? ''));
      } else if (columnIndex == 2) {
        _products.sort((a, b) => ascending
            ? _parsePrice(a['price']).compareTo(_parsePrice(b['price']))
            : _parsePrice(b['price']).compareTo(_parsePrice(a['price'])));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.business.botName,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                return isDesktop ? _buildDesktopTable() : _buildMobileList();
              },
            ),
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PaginatedDataTable(
        header: const Text('Управление товарами',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        rowsPerPage: _products.length > 50
            ? 50
            : (_products.isEmpty ? 1 : _products.length),
        showCheckboxColumn: false,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _isAscending,
        columns: [
          DataColumn(label: const Text('Название'), onSort: _onSort),
          const DataColumn(label: Text('Категория')),
          DataColumn(label: const Text('Цена'), onSort: _onSort, numeric: true),
          const DataColumn(label: Text('Действия')),
        ],
        source: _PriceDataSource(
          context: context,
          ref: ref,
          products: _products,
          business: widget.business,
          parsePrice: _parsePrice,
          onRefresh: _loadProducts,
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.accent,
      child: ListView.builder(
        itemCount: _products.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            color: AppColors.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(product['name'] ?? '',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(product['category'] ?? 'Общее',
                  style: const TextStyle(color: AppColors.textSecondary)),
              trailing: Text('${_parsePrice(product['price'])} AED',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold)),
              onTap: () async {
                final result = await context.push('/product-edit', extra: {
                  'business': widget.business,
                  'product': product,
                });
                if (result == true) _loadProducts();
              },
            ),
          );
        },
      ),
    );
  }
}

class _PriceDataSource extends DataTableSource {
  final BuildContext context;
  final WidgetRef ref;
  final List<Map<String, dynamic>> products;
  final Business business;
  final double Function(dynamic) parsePrice;
  final Future<void> Function() onRefresh;

  _PriceDataSource({
    required this.context,
    required this.ref,
    required this.products,
    required this.business,
    required this.parsePrice,
    required this.onRefresh,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= products.length) return null;
    final product = products[index];

    final String sku = (product['sku'] ?? '').toString();
    final botUrl = business.serviceUrl ?? '';

    return DataRow(cells: [
      DataCell(Text(product['name'] ?? '',
          style: const TextStyle(color: AppColors.textPrimary))),
      DataCell(Text(product['category'] ?? 'Общее',
          style: const TextStyle(color: AppColors.textSecondary))),
      DataCell(Text('${parsePrice(product['price'])} AED',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.accent))),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.penToSquare,
                  size: 16, color: AppColors.accent),
              onPressed: () async {
                final result = await context.push('/product-edit', extra: {
                  'business': business,
                  'product': product,
                });
                if (result == true) onRefresh();
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trashCan,
                  size: 16, color: AppColors.error),
              onPressed: () async {
                final confirmed = await _showDeleteDialog();
                if (confirmed) {
                  // ИСПРАВЛЕНО: Используем business.id (UUID) для удаления записи в БД инстанса
                  await ref.read(priceListRepositoryProvider).deleteProduct(
                        botUrl: botUrl,
                        businessId: business.id,
                        sku: sku,
                      );
                  onRefresh();
                }
              },
            ),
          ],
        ),
      ),
    ]);
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Удаление',
                style: TextStyle(color: AppColors.textPrimary)),
            content: const Text('Вы уверены, что хотите удалить этот товар?',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена',
                      style: TextStyle(color: AppColors.textSecondary))),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => products.length;
  @override
  int get selectedRowCount => 0;
}
