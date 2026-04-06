import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../services/stripe_service.dart';
import '../../domain/bot.dart';
import '../../providers/catalog_providers.dart';

class BotDetailScreen extends ConsumerStatefulWidget {
  final String category;

  const BotDetailScreen({super.key, required this.category});

  @override
  ConsumerState<BotDetailScreen> createState() => _BotDetailScreenState();
}

class _BotDetailScreenState extends ConsumerState<BotDetailScreen>
    with WidgetsBindingObserver {
  bool _isProActive = false;
  bool _isLoadingSub = true;
  bool _isWaitingForPayment = false; // Флаг: ушел ли юзер на оплату

  @override
  void initState() {
    super.initState();
    // Регистрируем наблюдателя за жизненным циклом
    WidgetsBinding.instance.addObserver(this);
    _checkProSubscription();
  }

  @override
  void dispose() {
    // Обязательно снимаем наблюдателя
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // МЕТОД: Ловим возврат пользователя из внешней вкладки Stripe
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForPayment) {
      debugPrint('✅ Приложение возобновлено (Resumed). Проверяем статус оплаты...');
      _verifySubscriptionAndNavigate();
    }
  }

  Future<void> _checkProSubscription() async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() => _isLoadingSub = false);
      }
      return;
    }

    try {
      final response = await supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .inFilter('plan', ['monthly_100', 'monthly_200']);

      if (mounted) {
        setState(() {
          _isProActive = response.isNotEmpty;
          _isLoadingSub = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSub = false);
      }
    }
  }

  // МЕТОД: Проверка в БД и навигация после оплаты
  Future<void> _verifySubscriptionAndNavigate() async {
    setState(() => _isWaitingForPayment = false); // Сбрасываем флаг

    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || !mounted) return;

    // Показываем диалог проверки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 24),
            Text(
              "Проверка платежа...",
              style: TextStyle(
                  color: AppColors.textPrimary, 
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              "Это займет пару секунд, не закрывайте приложение",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    try {
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 2));

        final response = await supabase
            .from('subscriptions')
            .select()
            .eq('user_id', userId)
            .eq('status', 'active')
            .maybeSingle();

        if (response != null) {
          debugPrint('💎 Подписка подтверждена!');

          final bots =
              await ref.read(botsByCategoryProvider(widget.category).future);
          final String currentBotId =
              bots.isNotEmpty ? bots.first.id : 'unknown';

          await supabase.from('businesses').upsert({
            'user_id': userId,
            'bot_id': currentBotId,
            'status': 'active',
          }, onConflict: 'user_id, bot_id');

          if (mounted) {
            Navigator.of(context).pop(); 
            final cat = widget.category;
            final botName = 'Dokki ${cat[0].toUpperCase()}${cat.substring(1)}';
            context.push('/bot-config/$currentBotId/$botName/$cat');
          }
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Оплата еще обрабатывается банком. Проверьте через минуту.")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = ref.watch(stringsProvider);
    final AppLanguage currentLang = ref.watch(languageProvider);
    final botsAsync = ref.watch(botsByCategoryProvider(widget.category));

    return botsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
            child: Text('Ошибка: $err',
                style: const TextStyle(color: AppColors.error))),
      ),
      data: (List<Bot> bots) {
        if (bots.isEmpty) {
          return const Scaffold(body: Center(child: Text('Бот не найден')));
        }

        final Bot bot = bots.first;
        final String fullDescription = bot.getLocalizedDescription(currentLang);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: const BackButton(color: AppColors.textPrimary),
            title: Text(bot.name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 1. ПОЛНЫЙ БЛОК ОПИСАНИЯ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.catDescription.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fullDescription,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. ПОЛНЫЙ БЛОК ФУНКЦИЙ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.catFunctions.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...bot.getLocalizedFeatures(currentLang).take(3).map((feature) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.accent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 3. КАРТОЧКА BASIC (6 ФУНКЦИЙ)
                _PlanCard(
                  s: s,
                  botId: bot.id,
                  title: 'Basic',
                  price: '\$50/${s.payMonth}',
                  planId: 'monthly_50',
                  features: [
                    s.planFeatureBot,
                    s.planFeatureUnlimitedMessages,
                    s.planFeaturePriceList,
                    s.planFeatureInstructions,
                    s.planFeatureChatHistory,
                    s.planFeatureTelegram,
                  ],
                  onStartPayment: () =>
                      setState(() => _isWaitingForPayment = true),
                ),

                // 4. КАРТОЧКА PRO (ПОЛНЫЙ СПИСОК)
                _isLoadingSub
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.accent),
                      )
                    : _PlanCard(
                        s: s,
                        botId: bot.id,
                        title: 'Pro',
                        price: '\$100/${s.payMonth}',
                        planId: 'monthly_100',
                        features: [
                          s.planFeaturePrivateDb,
                          s.planFeatureUnlimitedPrice,
                          s.planFeatureFullHistory,
                          s.planFeatureSocialMedia,
                          s.planFeatureInstructions,
                          s.planFeatureChatHistory,
                        ],
                        isProActive: _isProActive,
                        onStartPayment: () =>
                            setState(() => _isWaitingForPayment = true),
                      ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatefulWidget {
  final AppStrings s;
  final String botId;
  final String title;
  final String price;
  final String planId;
  final List<String> features;
  final bool isProActive;
  final VoidCallback onStartPayment;

  const _PlanCard({
    required this.s,
    required this.botId,
    required this.title,
    required this.price,
    required this.planId,
    required this.features,
    required this.onStartPayment,
    this.isProActive = false,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _isLoading = false;

  Future<void> _handleCheckout() async {
    setState(() => _isLoading = true);
    try {
      widget.onStartPayment();

      await StripeService().createCheckoutSession(
        botId: widget.botId,
        plan: widget.planId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.textPrimary)),
              Text(widget.price,
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          ...widget.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(feature,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          if (widget.isProActive)
            Center(
                child: Text(widget.s.planProActiveText,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold)))
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleCheckout,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(widget.s.botConnect.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}