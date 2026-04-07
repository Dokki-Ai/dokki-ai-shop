import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/business.dart';
import '../../providers/bot_management_providers.dart';
import '../../data/price_parser.dart';

class BotManagementScreen extends ConsumerStatefulWidget {
  final Business business;

  const BotManagementScreen({
    super.key,
    required this.business,
  });

  @override
  ConsumerState<BotManagementScreen> createState() =>
      _BotManagementScreenState();
}

class _BotManagementScreenState extends ConsumerState<BotManagementScreen> {
  late final TextEditingController _promptController;
  late final TextEditingController _botTokenController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _welcomeController;

  bool _isSaving = false;
  bool _obscureBotToken = true;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text: widget.business.systemPrompt ?? '',
    );
    _botTokenController = TextEditingController();
    _businessNameController = TextEditingController(
      text: widget.business.businessName.isNotEmpty
          ? widget.business.businessName
          : widget.business.botName,
    );
    _welcomeController = TextEditingController();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _botTokenController.dispose();
    _businessNameController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _deployBot() async {
    if (_botTokenController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final url = Uri.parse(ApiConstants.deployUrl);
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'businessId': Supabase.instance.client.auth.currentUser?.id ?? '',
              'botId': widget.business.botId,
              'botToken': _botTokenController.text.trim(),
              'businessName': _businessNameController.text.trim(),
              'welcomeMessage': _welcomeController.text.trim().isNotEmpty
                  ? _welcomeController.text.trim()
                  : 'Привет! Чем могу помочь?',
            }),
          )
          .timeout(const Duration(minutes: 3));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final telegramUsername = data['telegramUsername'] as String? ?? '';
        final railwayUrl = data['railwayUrl'] as String?;

        await ref.read(businessRepositoryProvider).connectBot(
              botId: widget.business.botId,
              botToken: _botTokenController.text.trim(),
              botName: widget.business.botName,
              botCategory: widget.business.botCategory,
              telegramUsername: telegramUsername,
              businessName: _businessNameController.text.trim(),
              alertsTopicId: 6,
              railwayUrl: railwayUrl,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Бот успешно запущен!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        throw Exception(data['error'] ?? 'Ошибка деплоя');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.rocket_launch_outlined, color: AppColors.accent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Подключите Telegram бота для запуска',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Токен бота',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _botTokenController,
            obscureText: _obscureBotToken,
            enabled: !_isSaving,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: '123456:ABC-DEF...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureBotToken ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureBotToken = !_obscureBotToken),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Название компании',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _businessNameController,
            enabled: !_isSaving,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Приветственное сообщение',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _welcomeController,
            maxLines: 3,
            enabled: !_isSaving,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _deployBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: AppColors.surface, strokeWidth: 2),
                    )
                  : const Text(
                      'ЗАПУСТИТЬ БОТА',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Метод выбора и обработки файла (Загрузка прайс-листа)
  Future<void> _pickPriceFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Используем URL напрямую из модели
      final botUrl = widget.business.railwayUrl ?? '';
      if (botUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('URL бота не найден. Свяжитесь с поддержкой.')),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final filePath = result.files.single.path!;
      final products = await PriceParser.parseFile(filePath);

      if (products.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Файл пуст или не распознан')),
          );
        }
        return;
      }

      // 1. Загружаем текущий прайс для поиска дубликатов
      final existing = await ref.read(priceListRepositoryProvider).getProducts(
            botUrl: botUrl,
            telegramUsername: widget.business.telegramUsername,
          );

      final existingNames = existing
          .map((p) => p['name'].toString().toLowerCase().trim())
          .toSet();

      final duplicates = products.where((p) {
        return existingNames
            .contains(p['name'].toString().toLowerCase().trim());
      }).length;

      if (!mounted) return;

      // 2. Диалог выбора режима импорта
      final mode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Загрузка ${products.length} товаров',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            duplicates > 0
                ? 'Найдено $duplicates совпадений. Выберите действие:'
                : 'Совпадений не найдено. Выберите действие:',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, 'replace'),
                    child: const Text(
                      'УДАЛИТЬ ВСЁ И ЗАГРУЗИТЬ ЗАНОВО',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, 'merge'),
                    child: const Text(
                      'ДОБАВИТЬ ТОЛЬКО НОВЫЕ',
                      style: TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text(
                      'ОТМЕНА',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (mode == null) return;

      // 3. Выполнение импорта через репозиторий
      bool success = false;

      if (mode == 'replace') {
        success = await ref.read(priceListRepositoryProvider).uploadPriceList(
              botUrl: botUrl,
              telegramUsername: widget.business.telegramUsername,
              products: products,
            );
      } else if (mode == 'merge') {
        final newProducts = products.where((p) {
          return !existingNames
              .contains(p['name'].toString().toLowerCase().trim());
        }).toList();

        if (newProducts.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Все товары уже есть в базе')),
            );
          }
          return;
        }

        success = await ref.read(priceListRepositoryProvider).addProducts(
              botUrl: botUrl,
              telegramUsername: widget.business.telegramUsername,
              products: newProducts,
            );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Прайс-лист успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка импорта: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Сохранение системного промпта
  Future<void> _handleSave() async {
    final botUrl = widget.business.railwayUrl ?? '';
    if (botUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('URL бота не найден. Свяжитесь с поддержкой.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bool success =
          await ref.read(botPromptRepositoryProvider).updateSystemPrompt(
                botUrl: botUrl,
                telegramUsername: widget.business.telegramUsername,
                systemPrompt: _promptController.text.trim(),
              );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Инструкции сохранены'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        title: Text(
          widget.business.botName,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: widget.business.status ==
                  'setup' // ИСПРАВЛЕНО: ориентируемся на статус
              ? _buildSetupView()
              : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Инструкции для ИИ',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _promptController,
                        maxLines: 6,
                        maxLength: 10000,
                        enabled: !_isSaving,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('СОХРАНИТЬ ИНСТРУКЦИИ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text('Прайс-лист',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        icon: Icons.list_alt_rounded,
                        label: 'Управление товарами',
                        onTap: () =>
                            context.push('/price-list', extra: widget.business),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuButton(
                        icon: Icons.upload_file_rounded,
                        label:
                            _isSaving ? 'Загрузка...' : 'Загрузить прайс-лист',
                        onTap: _isSaving ? null : _pickPriceFile,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
