import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/business.dart';
import '../../providers/bot_management_providers.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  final Business business;
  final Map<String, dynamic>? product;

  const ProductEditScreen({
    super.key,
    required this.business,
    this.product,
  });

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.product?['name'] ?? '');
    _priceController = TextEditingController(
      text: widget.product?['price']?.toString() ?? '',
    );
    _categoryController =
        TextEditingController(text: widget.product?['category'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Обработка сохранения товара
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // ИСПРАВЛЕНО: railwayUrl -> serviceUrl
    final botUrl = widget.business.serviceUrl ?? '';
    if (botUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL бота не найден.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final productData = {
      if (isEditing) 'id': widget.product!['id'],
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'category': _categoryController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    try {
      final success = await ref.read(priceListRepositoryProvider).updateProduct(
            botUrl: botUrl,
            telegramUsername: widget.business.telegramUsername,
            product: productData,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Успешно сохранено'),
              backgroundColor: Colors.green),
        );
        context.pop(true);
      } else if (mounted) {
        // Убрано упоминание Railway
        throw Exception('Ошибка при сохранении на сервере');
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Удаление товара
  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Удалить товар?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Позиция будет удалена из базы бота.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ОТМЕНА')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('УДАЛИТЬ', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ИСПРАВЛЕНО: railwayUrl -> serviceUrl
    final botUrl = widget.business.serviceUrl ?? '';
    if (botUrl.isEmpty) return;

    setState(() => _isSaving = true);

    final productId =
        (widget.product!['product_id'] ?? widget.product!['id']).toString();

    try {
      final success = await ref.read(priceListRepositoryProvider).deleteProduct(
            botUrl: botUrl,
            telegramUsername: widget.business.telegramUsername,
            productId: productId,
          );

      if (success && mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: Text(
          isEditing ? 'Редактирование' : 'Новый товар',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: _isSaving ? null : _handleDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Название товара *'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Напр: Консультация юриста',
                        validator: (v) =>
                            v!.isEmpty ? 'Это поле обязательно' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Цена *'),
                      _buildTextField(
                        controller: _priceController,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) => v!.isEmpty ? 'Укажите цену' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Категория'),
                      _buildTextField(
                        controller: _categoryController,
                        hint: 'Напр: Услуги или Товары',
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Описание'),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'Краткое описание для клиента...',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'СОХРАНИТЬ',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
