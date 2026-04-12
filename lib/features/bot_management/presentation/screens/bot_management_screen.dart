import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/business.dart';
import '../../providers/bot_management_providers.dart';

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

  /// Сохранение системного промпта
  Future<bool> _handleSave() async {
    final botUrl = widget.business.serviceUrl ?? '';
    if (botUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL бота не найден.')),
        );
      }
      return false;
    }

    try {
      final bool success =
          await ref.read(botPromptRepositoryProvider).updateSystemPrompt(
                botUrl: botUrl,
                businessId: widget.business.userId,
                systemPrompt: _promptController.text.trim(),
              );
      return success;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  /// Открытие модального окна с инструкциями
  void _showInstructionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Инструкции для ИИ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                maxLines: 10,
                maxLength: 10000,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  hintText: 'Опишите, как бот должен отвечать клиентам...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setModalState(() => _isSaving = true);
                          final success = await _handleSave();
                          setModalState(() => _isSaving = false);

                          if (!context.mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Инструкции сохранены'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'СОХРАНИТЬ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Метод развертывания бота (Оркестратор)
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
          .timeout(const Duration(minutes: 5));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final telegramUsername = data['telegramUsername'] as String? ?? '';
        final serviceUrl = data['url'] as String?;

        await ref.read(businessRepositoryProvider).connectBot(
              botId: widget.business.botId,
              botToken: _botTokenController.text.trim(),
              botName: widget.business.botName,
              botCategory: widget.business.botCategory,
              telegramUsername: telegramUsername,
              businessName: _businessNameController.text.trim(),
              alertsTopicId: 6,
              serviceUrl: serviceUrl,
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
        child: widget.business.status == 'setup'
            ? _buildSetupView()
            : SingleChildScrollView(
                // УБРАЛИ Center, чтобы список начинался сверху
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20), // Отступ от шапки

                    // ГРУППА 1: ИНСТРУКЦИИ
                    _buildSectionHeader('Инструкции для AI бота'),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.psychology_alt_rounded,
                      label: 'Настроить инструкции',
                      onTap: _showInstructionsSheet,
                    ),

                    const SizedBox(height: 32),

                    // ГРУППА 2: ПРАЙС-ЛИСТ
                    _buildSectionHeader('Прайс-лист'),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.list_alt_rounded,
                      label: 'Управление товарами',
                      enabled: widget.business.botCategory == 'sales',
                      onTap: () =>
                          context.push('/price-list', extra: widget.business),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.price_change_rounded,
                      label: 'Загрузить прайс-лист',
                      enabled: widget.business.botCategory == 'sales',
                      onTap: () => context.push('/upload', extra: {
                        'business': widget.business,
                        'uploadType': 'prices'
                      }),
                    ),

                    const SizedBox(height: 32),

                    // ГРУППА 3: БАЗА ЗНАНИЙ
                    _buildSectionHeader('База знаний'),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.library_books_rounded,
                      label: 'Управление документами',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Будет доступно позже')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.auto_stories_rounded,
                      label: 'Загрузить базу знаний',
                      onTap: () => context.push('/upload', extra: {
                        'business': widget.business,
                        'uploadType': 'knowledge'
                      }),
                    ),
                    const SizedBox(height: 40), // Запас снизу для скролла
                  ],
                ),
              ),
      ),
    );
  }

  /// Вспомогательный метод для заголовков секций
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              enabled ? AppColors.card : AppColors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled
                  ? AppColors.accent
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!enabled)
                    const Text(
                      'Недоступно для этого типа бота',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
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
}
