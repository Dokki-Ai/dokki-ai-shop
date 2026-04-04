import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
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
  final _apiKeyController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _welcomeController = TextEditingController();

  String? _botTokenError;
  String? _apiKeyError;
  String? _businessNameError;

  bool _isLoading = false;
  bool _obscureApiKey = true;
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
    _apiKeyController.dispose();
    _businessNameController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() {
      _botTokenError = null;
      _apiKeyError = null;
      _businessNameError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(ApiConstants.configUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telegram_token': _botTokenController.text.trim(),
          'openai_key': _apiKeyController.text.trim(),
          'business_name': _businessNameController.text.trim(),
          'welcome_message': _welcomeController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final telegramUsername = data['username'] as String? ?? '';

        await ref.read(businessRepositoryProvider).connectBot(
              botId: widget.botId,
              botToken: _botTokenController.text.trim(),
              botName: widget.botName,
              botCategory: widget.botCategory,
              telegramUsername: telegramUsername,
              businessName: _businessNameController.text.trim(),
              openaiKey: _apiKeyController.text.trim(),
              alertsTopicId: 6,
            );

        if (mounted) _showSuccessDialog(telegramUsername);
      } else {
        final errorMessage = data['error'] ?? 'Ошибка сохранения';
        final errorField = data['field'];

        setState(() {
          if (errorField == 'telegram_token') _botTokenError = errorMessage;
          if (errorField == 'openai_key') _apiKeyError = errorMessage;
          if (errorField == 'business_name') _businessNameError = errorMessage;
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
        title: const Text('✅ Бот подключён!',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Ваш бот $username готов к работе.\n\nНапишите ему /start в Telegram для проверки.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Перейти к ботам',
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
        title: const Text('Настройка ИИ'),
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
                        Icon(Icons.info_outline, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('Как подключить бота',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1. Откройте @BotFather в Telegram',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text('2. Отправьте команду /newbot',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text('3. Следуйте инструкциям',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text('4. Скопируйте токен бота',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TELEGRAM BOT TOKEN С ЛОГАМИ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _botTokenController,
                      obscureText: _obscureBotToken,
                      autofillHints: const [AutofillHints.password],
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Введите токен';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.content_paste,
                          color: AppColors.accent, size: 28),
                      onPressed: () async {
                        debugPrint('🔵 TG Paste button clicked!');
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        debugPrint(
                            '📋 Clipboard data: ${data?.text ?? "NULL"}');

                        if (data?.text != null) {
                          debugPrint('✅ Setting TG text to controller');
                          setState(() {
                            _botTokenController.text = data!.text!;
                            _botTokenError = null;
                          });
                        } else {
                          debugPrint('❌ TG Clipboard is empty');
                        }
                      },
                      tooltip: 'Paste',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // OPENAI API KEY С ЛОГАМИ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _apiKeyController,
                      obscureText: _obscureApiKey,
                      autofillHints: const [AutofillHints.password],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _buildDecor(
                        'OpenAI API Key',
                        'sk-proj-...',
                        suffix: IconButton(
                          icon: Icon(
                              _obscureApiKey
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.textSecondary),
                          onPressed: () =>
                              setState(() => _obscureApiKey = !_obscureApiKey),
                        ),
                      ).copyWith(errorText: _apiKeyError),
                      validator: (v) {
                        final key = v?.trim() ?? "";
                        if (key.isEmpty) return 'Введите ключ API';
                        if (!key.startsWith('sk-')) {
                          return 'Должен начинаться с "sk-"';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.content_paste,
                          color: AppColors.accent, size: 28),
                      onPressed: () async {
                        debugPrint('🔵 OpenAI Paste button clicked!');
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        debugPrint(
                            '📋 Clipboard data: ${data?.text ?? "NULL"}');

                        if (data?.text != null) {
                          debugPrint('✅ Setting OpenAI text to controller');
                          setState(() {
                            _apiKeyController.text = data!.text!;
                            _apiKeyError = null;
                          });
                        } else {
                          debugPrint('❌ OpenAI Clipboard is empty');
                        }
                      },
                      tooltip: 'Paste',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _businessNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    _buildDecor('Название компании', 'Напр: Dokki Sales')
                        .copyWith(errorText: _businessNameError),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Введите название';
                  return null;
                },
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
                          'ПОДКЛЮЧИТЬ БОТА',
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
