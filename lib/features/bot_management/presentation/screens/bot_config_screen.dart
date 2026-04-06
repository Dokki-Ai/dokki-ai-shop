import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/bot_management_providers.dart';

class BotConfigScreen extends ConsumerStatefulWidget {
  final String botId;
  final String botName;
  final String botCategory;

  const BotConfigScreen({
    super.key,
    required this.botId,
    required this.botName,
    required this.botCategory,
  });

  @override
  ConsumerState<BotConfigScreen> createState() => _BotConfigScreenState();
}

class _BotConfigScreenState extends ConsumerState<BotConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _botTokenController = TextEditingController();
  // УДАЛЕНО: _apiKeyController
  final _businessNameController = TextEditingController();
  final _welcomeController = TextEditingController();

  String? _botTokenError;
  // УДАЛЕНО: _apiKeyError
  String? _businessNameError;

  bool _isLoading = false;
  // УДАЛЕНО: _obscureApiKey
  bool _obscureBotToken = true;

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    _businessNameController.text = widget.botName;
    _welcomeController.text =
        'Здравствуйте! Вас приветствует ${widget.botName}. Чем могу помочь?';
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    // УДАЛЕНО: _apiKeyController.dispose()
    _businessNameController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() {
      _botTokenError = null;
      // УДАЛЕНО: _apiKeyError = null
      _businessNameError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(ApiConstants.deployUrl);

      // Отправляем запрос на оркестратор деплоя
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'businessId': Supabase.instance.client.auth.currentUser?.id ?? '',
              'botId': widget.botId,
              'botToken': _botTokenController.text.trim(),
              // УДАЛЕНО: 'openaiKey'
              'businessName': _businessNameController.text.trim(),
              'welcomeMessage': _welcomeController.text.trim(),
            }),
          )
          .timeout(const Duration(minutes: 3));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final telegramUsername = data['telegramUsername'] as String? ?? '';

        // Сохраняем локально и в репозиторий бизнеса
        await ref.read(businessRepositoryProvider).connectBot(
              botId: widget.botId,
              botToken: _botTokenController.text.trim(),
              botName: widget.botName,
              botCategory: widget.botCategory,
              telegramUsername: telegramUsername,
              businessName: _businessNameController.text.trim(),
              // УДАЛЕНО: openaiKey
              alertsTopicId: 6,
            );

        if (mounted) _showSuccessDialog(telegramUsername);
      } else {
        final errorMessage = data['error'] ?? 'Ошибка деплоя';
        final errorField = data['field'];

        setState(() {
          if (errorField == 'botToken') _botTokenError = errorMessage;
          // УДАЛЕНО: обработка ошибки openaiKey
          if (errorField == 'businessName') _businessNameError = errorMessage;
        });

        throw Exception(errorMessage);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('✅ Бот в очереди на деплой!',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Ваш бот $username создаётся на сервере.\n\nЭто займёт 1-2 минуты. Бот сам напишет вам в Telegram, когда будет готов.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Понятно',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildDecor(String label, String hint, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      filled: true,
      fillColor: AppColors.card,
      suffixIcon: suffix,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Настройка и Деплой'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.rocket_launch_outlined,
                            color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('Запуск персонального бота',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                        'Мы создадим для вас отдельный проект на Railway и запустим в нём вашего ИИ-ассистента.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TELEGRAM BOT TOKEN
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _botTokenController,
                      obscureText: _obscureBotToken,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _buildDecor(
                        'Telegram Bot Token',
                        '123456:ABC-DEF...',
                        suffix: IconButton(
                          icon: Icon(
                              _obscureBotToken
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.textSecondary),
                          onPressed: () => setState(
                              () => _obscureBotToken = !_obscureBotToken),
                        ),
                      ).copyWith(errorText: _botTokenError),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Введите токен' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.content_paste,
                          color: AppColors.accent, size: 28),
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          setState(() {
                            _botTokenController.text = data!.text!;
                            _botTokenError = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // УДАЛЕНО: Весь блок OPENAI API KEY

              TextFormField(
                controller: _businessNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    _buildDecor('Название компании', 'Напр: Dokki Sales')
                        .copyWith(errorText: _businessNameError),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _welcomeController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    _buildDecor('Приветствие', 'Что бот скажет первым?'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'ЗАПУСТИТЬ ДЕПЛОЙ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
