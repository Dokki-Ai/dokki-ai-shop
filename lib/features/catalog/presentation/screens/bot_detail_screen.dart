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

class _BotDetailScreenState extends ConsumerState<BotDetailScreen> {
  bool _isProActive = false;
  bool _isLoadingSub = true;

  @override
  void initState() {
    super.initState();
    _checkProSubscription();
  }

  Future<void> _checkProSubscription() async {
    final supabase = ref.read(supabaseClientProvider);
    final session = supabase.auth.currentSession;
    if (session == null) {
      if (mounted) setState(() => _isLoadingSub = false);
      return;
    }

    try {
      final response = await supabase
          .from('subscriptions')
          .select()
          .eq('user_id', session.user.id)
          .eq('status', 'active')
          .inFilter('plan', ['monthly_100', 'monthly_200']);

      if (mounted) {
        setState(() {
          _isProActive = response.isNotEmpty;
          _isLoadingSub = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSub = false);
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
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (List<Bot> bots) {
        if (bots.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Информация временно недоступна')),
          );
        }

        final Bot bot = bots.first;
        final String fullDescription = bot.getLocalizedDescription(currentLang);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: const BackButton(color: AppColors.textPrimary),
            title: Text(
              bot.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 1. Описание (ИСПРАВЛЕНО: Flex: 2)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
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
                      Expanded(
                        child: Text(
                          fullDescription,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Функции из БД (ИСПРАВЛЕНО: Flex: 2)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
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
                      ...bot
                          .getLocalizedFeatures(currentLang)
                          .take(3)
                          .map((feature) {
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // 3. Basic карточка (ИСПРАВЛЕНО: Flex: 4)
              Expanded(
                flex: 4,
                child: _PlanCard(
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
                ),
              ),

              // 4. Pro карточка (ИСПРАВЛЕНО: Flex: 4)
              Expanded(
                flex: 4,
                child: _isLoadingSub
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
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
                        ],
                        isProActive: _isProActive,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanCard extends ConsumerStatefulWidget {
  final AppStrings s;
  final String botId;
  final String title;
  final String price;
  final String planId;
  final List<String> features;
  final bool isProActive;

  const _PlanCard({
    required this.s,
    required this.botId,
    required this.title,
    required this.price,
    required this.planId,
    required this.features,
    this.isProActive = false,
  });

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  bool _isLoading = false;

  Future<void> _handleCheckout() async {
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) {
      context.push('/auth');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await StripeService().createCheckoutSession(
        botId: widget.botId,
        plan: widget.planId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.price,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: widget.features
                  .map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.isProActive)
            Center(
              child: Text(
                widget.s.planProActiveText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleCheckout,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.s.botConnect.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
