import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/app_strings.dart';
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
  final _businessNameController = TextEditingController();
  final _welcomeController = TextEditingController();

  String? _botTokenError;
  String? _businessNameError;

  bool _isLoading = false;
  bool _obscureBotToken = true;

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    final s = AppStrings(AppStrings.currentLanguage);
    _businessNameController.text = widget.botName;
    _welcomeController.text = s.botConfigDefaultWelcome(widget.botName);
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    _businessNameController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() {
      _botTokenError = null;
      _businessNameError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(ApiConstants.deployUrl);

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'businessId': Supabase.instance.client.auth.currentUser?.id ?? '',
              'botId': widget.botId,
              'botToken': _botTokenController.text.trim(),
              'businessName': _businessNameController.text.trim(),
              'welcomeMessage': _welcomeController.text.trim(),
            }),
          )
          .timeout(const Duration(minutes: 3));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final telegramUsername = data['telegramUsername'] as String? ?? '';

        // ИСПРАВЛЕНО: Берем 'url' из ответа и называем переменную serviceUrl
        final serviceUrl = data['url'] as String?;

        await ref.read(businessRepositoryProvider).connectBot(
              botId: widget.botId,
              botToken: _botTokenController.text.trim(),
              botName: widget.botName,
              botCategory: widget.botCategory,
              telegramUsername: telegramUsername,
              businessName: _businessNameController.text.trim(),
              alertsTopicId: 6,
              // ИСПРАВЛЕНО: Переименовано в serviceUrl
              serviceUrl: serviceUrl,
            );

        if (mounted) _showSuccessDialog();
      } else {
        final errorMessage = data['error'] ?? 'Deploy error';
        final errorField = data['field'];

        setState(() {
          if (errorField == 'botToken') _botTokenError = errorMessage;
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

  void _showSuccessDialog() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.botConfigSuccess,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          s.botConfigSuccessHint,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: Text(
              s.botConfigOk,
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
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
    final s = ref.watch(stringsProvider);
    // ignore: unused_local_variable
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.botConfigTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.rocket_launch_outlined,
                            color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          s.botConfigTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.botConfigSubtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _botTokenController,
                obscureText: _obscureBotToken,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _buildDecor(
                  s.botConfigTokenLabel,
                  '123456:ABC-DEF...',
                  suffix: IconButton(
                    icon: Icon(
                      _obscureBotToken
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureBotToken = !_obscureBotToken),
                  ),
                ).copyWith(errorText: _botTokenError),
                validator: (v) =>
                    (v == null || v.isEmpty) ? s.botConfigTokenRequired : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _businessNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    _buildDecor(s.botConfigCompanyLabel, 'Dokki Business')
                        .copyWith(errorText: _businessNameError),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.botConfigNameRequired
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _welcomeController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _buildDecor(s.botConfigWelcomeLabel, ''),
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
                      : Text(
                          s.botConfigDeploy,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
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
