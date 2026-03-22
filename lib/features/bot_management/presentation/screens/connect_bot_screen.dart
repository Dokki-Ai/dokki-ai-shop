import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/env/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../catalog/providers/catalog_providers.dart';
import '../../providers/bot_management_providers.dart';

class ConnectBotScreen extends ConsumerStatefulWidget {
  final String botId;
  final String botName;

  const ConnectBotScreen({
    super.key,
    required this.botId,
    required this.botName,
  });

  @override
  ConsumerState<ConnectBotScreen> createState() => _ConnectBotScreenState();
}

class _ConnectBotScreenState extends ConsumerState<ConnectBotScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _botTokenController = TextEditingController();
  final _railwayTokenController = TextEditingController();
  final _workspaceIdController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _botTokenController.dispose();
    _railwayTokenController.dispose();
    _workspaceIdController.dispose();
    super.dispose();
  }

  // Шаг 1: Проверка токена Telegram
  Future<void> _validateTelegramAndProceed() async {
    final token = _botTokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите токен Telegram')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Валидация токена через провайдер
      await ref.read(telegramRepositoryProvider).validateToken(token);

      // Переход на следующий экран
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Шаг 2: Подключение Railway, сохранение в Supabase и деплой
  Future<void> _connect() async {
    final botToken = _botTokenController.text.trim();
    final railwayToken = _railwayTokenController.text.trim();
    final workspaceId = _workspaceIdController.text.trim();

    if (railwayToken.isEmpty || workspaceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните данные Railway')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Сохранить в Supabase
      final result = await ref.read(businessRepositoryProvider).connectBot(
            botId: widget.botId,
            botToken: botToken,
            railwayToken: railwayToken,
            railwayWorkspaceId: workspaceId,
          );

      // 2. Получить github_repo из bot_catalog
      final bot = await ref.read(botByIdProvider(widget.botId).future);

      // 3. Вызвать deploy-service
      await http.post(
        Uri.parse('${Env.deployServiceUrl}/deploy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'businessId': result.id,
          'botId': widget.botId,
          'botToken': botToken,
          'githubRepo': bot?.githubRepo,
          'railwayToken': railwayToken,
          'railwayWorkspaceId': workspaceId,
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бот успешно отправлен на деплой!'),
            backgroundColor: Colors.green,
          ),
        );

        context.pushReplacement(
          '/bot-management/${result.id}',
          extra: result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentStep == 0
            ? 'Шаг 1: Подключение Telegram'
            : 'Шаг 2: Настройка сервера'),
        centerTitle: false,
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  setState(() => _currentStep = 0);
                },
              )
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Блокируем ручной свайп
        children: [
          _buildTelegramStep(),
          _buildRailwayStep(),
        ],
      ),
    );
  }

  Widget _buildTelegramStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ИНСТРУКЦИЯ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Text(
              '1. Откройте @BotFather.\n'
              '2. Сгенерируйте НОВЫЙ токен (Revoke), если старый был скомпрометирован.\n'
              '3. Вставьте новый токен в поле ниже.',
              style: TextStyle(height: 1.6, color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'API ТОКЕН',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _botTokenController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration:
                _buildInputDecoration('Bot API Token', Icons.vpn_key_rounded),
            enabled: !_isLoading,
            autocorrect: false,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _validateTelegramAndProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'ПРОВЕРИТЬ И ПРОДОЛЖИТЬ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailwayStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ИНСТРУКЦИЯ RAILWAY',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Text(
              '1. Войдите в аккаунт Railway.\n'
              '2. Создайте API Token в настройках профиля.\n'
              '3. Скопируйте ваш Workspace ID.',
              style: TextStyle(height: 1.6, color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'RAILWAY API TOKEN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _railwayTokenController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _buildInputDecoration(
                'Railway Token', Icons.cloud_queue_rounded),
            enabled: !_isLoading,
            autocorrect: false,
          ),
          const SizedBox(height: 24),
          const Text(
            'WORKSPACE ID',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _workspaceIdController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration:
                _buildInputDecoration('Workspace ID', Icons.grid_view_rounded),
            enabled: !_isLoading,
            autocorrect: false,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'ПОДКЛЮЧИТЬ И ЗАДЕПЛОИТЬ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
